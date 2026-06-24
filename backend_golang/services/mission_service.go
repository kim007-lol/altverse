package services

import (
	"errors"
	"time"

	"aureader/backend/errorhandler"
	"aureader/backend/models"
	"aureader/backend/repositories"

	"gorm.io/gorm"
)

// activityMissionMap mirrors MissionService.php autoTrack().
var activityMissionMap = map[string][]string{
	"login":        {"daily_login"},
	"read_episode": {"daily_read_5", "weekly_read_25"},
	"comment":      {"daily_comment_3", "weekly_comment_15"},
	"like_episode": {"daily_like_5"},
	"follow":       {"weekly_follow_5"},
	"bookmark":     {"weekly_bookmark_5"},
}

type MissionStatus struct {
	ID          uint64     `json:"id"`
	Title       string     `json:"title"`
	Description *string    `json:"description"`
	Type        string     `json:"type"`
	XPReward    int        `json:"xp_reward"`
	CoinReward  int        `json:"coin_reward"`
	Target      int        `json:"target"`
	Progress    int        `json:"progress"`
	IsCompleted bool       `json:"is_completed"`
	IsClaimed   bool       `json:"is_claimed"`
	CanClaim    bool       `json:"can_claim"`
	CompletedAt *time.Time `json:"completed_at"`
	ClaimedAt   *time.Time `json:"claimed_at"`
}

type ClaimResult struct {
	XPReward   int `json:"xp_reward"`
	CoinReward int `json:"coin_reward"`
}

type MissionService interface {
	GetUserMissions(userID uint64) ([]MissionStatus, error)
	TrackActivity(userID uint64, activity string)
	ClaimReward(userID uint64, missionID uint64) (*ClaimResult, error)
}

type missionService struct {
	gamRepo  repositories.GamificationRepository
	userRepo repositories.UserRepository
	xpSvc    XPService
}

func NewMissionService(gamRepo repositories.GamificationRepository, userRepo repositories.UserRepository, xpSvc XPService) MissionService {
	return &missionService{gamRepo: gamRepo, userRepo: userRepo, xpSvc: xpSvc}
}

func (s *missionService) GetUserMissions(userID uint64) ([]MissionStatus, error) {
	missions, err := s.gamRepo.GetActiveMissions()
	if err != nil {
		return nil, err
	}

	today := time.Now().Format("2006-01-02")
	weekStart := weekStartDate()

	result := make([]MissionStatus, 0, len(missions))
	for _, m := range missions {
		um, err := s.gamRepo.GetUserMission(userID, m.ID)
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			continue
		}

		progress := 0
		var completedAt, claimedAt *time.Time

		if um != nil {
			// Reset stale progress for daily/weekly missions
			needsReset := false
			if m.Type == "daily" && um.UpdatedAt.Format("2006-01-02") != today {
				needsReset = true
			} else if m.Type == "weekly" && um.UpdatedAt.Format("2006-01-02") < weekStart {
				needsReset = true
			}

			if needsReset {
				um.Progress = 0
				um.Status = "in_progress"
				um.CompletedAt = nil
				um.ClaimedAt = nil
				_ = s.gamRepo.UpdateUserMission(um)
			}

			progress = um.Progress
			completedAt = um.CompletedAt
			claimedAt = um.ClaimedAt
		}

		isCompleted := completedAt != nil
		isClaimed := claimedAt != nil

		result = append(result, MissionStatus{
			ID:          m.ID,
			Title:       m.Title,
			Description: m.Description,
			Type:        m.Type,
			XPReward:    m.XPReward,
			CoinReward:  m.CoinReward,
			Target:      m.ConditionValue,
			Progress:    progress,
			IsCompleted: isCompleted,
			IsClaimed:   isClaimed,
			CanClaim:    isCompleted && !isClaimed,
			CompletedAt: completedAt,
			ClaimedAt:   claimedAt,
		})
	}
	return result, nil
}

func (s *missionService) TrackActivity(userID uint64, activity string) {
	codes, ok := activityMissionMap[activity]
	if !ok {
		return
	}
	for _, code := range codes {
		s.trackByCode(userID, code, 1)
	}
}

func (s *missionService) trackByCode(userID uint64, code string, increment int) {
	missions, err := s.gamRepo.GetActiveMissions()
	if err != nil {
		return
	}

	var mission *models.Mission
	for i := range missions {
		if missions[i].ConditionType == code {
			mission = &missions[i]
			break
		}
	}
	if mission == nil {
		return
	}

	today := time.Now().Format("2006-01-02")
	weekStart := weekStartDate()

	um, err := s.gamRepo.GetUserMission(userID, mission.ID)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		um = &models.UserMission{
			UserID:    userID,
			MissionID: mission.ID,
			Status:    "in_progress",
			Progress:  0,
		}
	} else if err != nil {
		return
	}

	// Once missions: skip if already claimed
	if mission.Type == "onetime" && um.ClaimedAt != nil {
		return
	}

	// Reset if stale
	if mission.Type == "daily" && um.UpdatedAt.Format("2006-01-02") != today {
		um.Progress = 0
		um.CompletedAt = nil
		um.ClaimedAt = nil
	} else if mission.Type == "weekly" && um.UpdatedAt.Format("2006-01-02") < weekStart {
		um.Progress = 0
		um.CompletedAt = nil
		um.ClaimedAt = nil
	}

	newProgress := um.Progress + increment
	if newProgress > mission.ConditionValue {
		newProgress = mission.ConditionValue
	}
	um.Progress = newProgress

	if newProgress >= mission.ConditionValue && um.CompletedAt == nil {
		now := time.Now()
		um.CompletedAt = &now
		um.Status = "completed"
	}

	_ = s.gamRepo.UpsertUserMission(um)
}

func (s *missionService) ClaimReward(userID uint64, missionID uint64) (*ClaimResult, error) {
	um, err := s.gamRepo.GetUserMission(userID, missionID)
	if err != nil {
		return nil, errorhandler.NewNotFound("mission progress not found")
	}
	if um.CompletedAt == nil {
		return nil, errorhandler.NewBadRequest("mission not completed yet")
	}
	if um.ClaimedAt != nil {
		return nil, errorhandler.NewConflict("reward already claimed")
	}

	missions, _ := s.gamRepo.GetActiveMissions()
	var mission *models.Mission
	for i := range missions {
		if missions[i].ID == missionID {
			mission = &missions[i]
			break
		}
	}
	if mission == nil {
		return nil, errorhandler.NewNotFound("mission not found")
	}

	// Atomic claim: only the winner of a double-claim race flips claimed_at,
	// so the reward is granted exactly once.
	claimed, err := s.gamRepo.ClaimMissionReward(userID, missionID)
	if err != nil {
		return nil, errorhandler.NewInternalError("failed to claim reward")
	}
	if !claimed {
		return nil, errorhandler.NewConflict("reward already claimed")
	}

	if mission.XPReward > 0 {
		_, _, _ = s.xpSvc.AwardXP(userID, "mission_complete", mission.XPReward)
	}
	if mission.CoinReward > 0 {
		// Atomic increment avoids the lost-update race of read-modify-write.
		_ = s.userRepo.AddCoins(userID, mission.CoinReward)
	}

	return &ClaimResult{XPReward: mission.XPReward, CoinReward: mission.CoinReward}, nil
}

func weekStartDate() string {
	t := time.Now()
	offset := int(t.Weekday())
	if offset == 0 {
		offset = 7
	}
	start := t.AddDate(0, 0, -(offset - 1))
	return start.Format("2006-01-02")
}
