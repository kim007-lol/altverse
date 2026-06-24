package services

import (
	"errors"
	"time"

	"aureader/backend/models"
	"aureader/backend/repositories"

	"gorm.io/gorm"
)

// XP per source — caps prevent daily farming.
var xpSourceConfig = map[string]struct {
	Amount   int
	DailyCap int // 0 = unlimited
}{
	"login":            {Amount: 10, DailyCap: 10},
	"read_episode":     {Amount: 5, DailyCap: 50},
	"comment":          {Amount: 5, DailyCap: 25},
	"follow":           {Amount: 3, DailyCap: 15},
	"bookmark":         {Amount: 2, DailyCap: 10},
	"like_episode":     {Amount: 1, DailyCap: 10},
	"mission_complete": {Amount: 0, DailyCap: 0}, // XP set by mission itself
}

// XP thresholds per level (level = index+1).
var levelThresholds = []int{
	0, 100, 250, 500, 900, 1400, 2100, 3000, 4200, 5700,
	7500, 10000, 13000, 16500, 20500, 25000, 30000, 36000, 43000, 51000,
}

func CalculateLevel(totalXP int) int {
	level := 1
	for i, threshold := range levelThresholds {
		if totalXP >= threshold {
			level = i + 1
		} else {
			break
		}
	}
	return level
}

type XPService interface {
	AwardXP(userID uint64, source string, customAmount int) (xpEarned int, newLevel int, err error)
	GetUserXP(userID uint64) (*models.UserXP, error)
}

type xpService struct {
	gamRepo repositories.GamificationRepository
}

func NewXPService(gamRepo repositories.GamificationRepository) XPService {
	return &xpService{gamRepo: gamRepo}
}

// AwardXP grants XP to a user respecting daily caps.
// Pass customAmount=0 to use the source default; pass >0 to override (e.g. mission reward).
func (s *xpService) AwardXP(userID uint64, source string, customAmount int) (int, int, error) {
	cfg, known := xpSourceConfig[source]
	if !known && customAmount == 0 {
		return 0, 0, nil // unknown source, no-op
	}

	amount := cfg.Amount
	if customAmount > 0 {
		amount = customAmount
	}
	if amount == 0 {
		return 0, 0, nil
	}

	today := time.Now().Truncate(24 * time.Hour)

	// Enforce daily cap
	if cfg.DailyCap > 0 {
		existing, err := s.gamRepo.GetDailyXPLog(userID, source, today)
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			return 0, 0, err
		}
		if err == nil {
			remaining := cfg.DailyCap - existing.XPEarned
			if remaining <= 0 {
				return 0, 0, nil // daily cap hit
			}
			if amount > remaining {
				amount = remaining
			}
		}
	}

	// Log the XP
	if err := s.gamRepo.CreateDailyXPLog(&models.DailyXPLog{
		UserID:   userID,
		Source:   source,
		XPEarned: amount,
		LogDate:  today,
	}); err != nil {
		// If UNIQUE violation (same source+date already logged), add to it via upsert — ignore here
		_ = err
	}

	// Update cumulative XP
	existing, err := s.gamRepo.GetUserXP(userID)
	totalXP := amount
	if err == nil {
		totalXP += existing.TotalXP
	}

	newLevel := CalculateLevel(totalXP)
	if err := s.gamRepo.UpsertUserXP(&models.UserXP{
		UserID:       userID,
		TotalXP:      totalXP,
		CurrentLevel: newLevel,
	}); err != nil {
		return 0, 0, err
	}

	// Sync season XP if a season is active
	if season, err := s.gamRepo.GetActiveSeason(); err == nil {
		sxp := &models.SeasonXP{UserID: userID, SeasonID: season.ID}
		if existing, err := s.gamRepo.GetSeasonXP(userID, season.ID); err == nil {
			sxp.XP = existing.XP + amount
		} else {
			sxp.XP = amount
		}
		_ = s.gamRepo.UpsertSeasonXP(sxp)
	}

	return amount, newLevel, nil
}

func (s *xpService) GetUserXP(userID uint64) (*models.UserXP, error) {
	return s.gamRepo.GetUserXP(userID)
}
