package services

import (
	"aureader/backend/models"
	"aureader/backend/repositories"
)

// Badge condition types (match gam_badges.condition_type).
const (
	BadgeCondFollowers = "followers_count"
	BadgeCondCoinsSpent = "coins_spent"
	BadgeCondReads     = "episodes_read"
	BadgeCondFollows   = "follows_count"
)

type BadgeService interface {
	CheckAndAwardBadges(userID uint64) []models.Badge
	AwardBadge(userID uint64, slug string) error
	GetUserBadges(userID uint64) ([]models.UserBadge, error)
	GetAllBadges() ([]models.Badge, error)
}

type badgeService struct {
	gamRepo    repositories.GamificationRepository
	socialRepo repositories.SocialRepository
	trackRepo  repositories.TrackingRepository
}

func NewBadgeService(
	gamRepo repositories.GamificationRepository,
	socialRepo repositories.SocialRepository,
	trackRepo repositories.TrackingRepository,
) BadgeService {
	return &badgeService{
		gamRepo:    gamRepo,
		socialRepo: socialRepo,
		trackRepo:  trackRepo,
	}
}

func (s *badgeService) GetAllBadges() ([]models.Badge, error) {
	return s.gamRepo.GetAllBadges()
}

func (s *badgeService) GetUserBadges(userID uint64) ([]models.UserBadge, error) {
	return s.gamRepo.GetUserBadges(userID)
}

func (s *badgeService) AwardBadge(userID uint64, slug string) error {
	badge, err := s.gamRepo.GetBadgeBySlug(slug)
	if err != nil {
		return err
	}
	return s.gamRepo.AwardBadge(userID, badge.ID)
}

// CheckAndAwardBadges evaluates all badge conditions for a user and awards
// any newly earned badges. Returns the list of newly awarded badges.
func (s *badgeService) CheckAndAwardBadges(userID uint64) []models.Badge {
	allBadges, err := s.gamRepo.GetAllBadges()
	if err != nil {
		return nil
	}

	var newlyAwarded []models.Badge

	// Collect current stats once
	_, followersTotal, _ := s.socialRepo.GetFollowers(userID, 1, 1)
	_, followingTotal, _ := s.socialRepo.GetFollowing(userID, 1, 1)
	_, readTotal, _ := s.trackRepo.FindReadingHistoriesByUser(userID, 1, 1)

	stats := map[string]int64{
		BadgeCondFollowers: followersTotal,
		BadgeCondFollows:   followingTotal,
		BadgeCondReads:     readTotal,
	}

	for _, badge := range allBadges {
		has, err := s.gamRepo.HasBadge(userID, badge.ID)
		if err != nil || has {
			continue
		}

		stat, ok := stats[badge.ConditionType]
		if !ok {
			continue
		}

		if int64(badge.ConditionValue) <= stat {
			if err := s.gamRepo.AwardBadge(userID, badge.ID); err == nil {
				newlyAwarded = append(newlyAwarded, badge)
			}
		}
	}

	return newlyAwarded
}
