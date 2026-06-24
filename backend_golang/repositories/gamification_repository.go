package repositories

import (
	"time"

	"aureader/backend/models"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type GamificationRepository interface {
	// XP
	GetUserXP(userID uint64) (*models.UserXP, error)
	UpsertUserXP(xp *models.UserXP) error
	GetDailyXPLog(userID uint64, source string, date time.Time) (*models.DailyXPLog, error)
	CreateDailyXPLog(log *models.DailyXPLog) error
	// Badges
	GetAllBadges() ([]models.Badge, error)
	GetBadgeBySlug(slug string) (*models.Badge, error)
	GetUserBadges(userID uint64) ([]models.UserBadge, error)
	HasBadge(userID, badgeID uint64) (bool, error)
	AwardBadge(userID, badgeID uint64) error
	// Missions
	GetActiveMissions() ([]models.Mission, error)
	GetUserMissions(userID uint64) ([]models.UserMission, error)
	GetUserMission(userID, missionID uint64) (*models.UserMission, error)
	UpsertUserMission(um *models.UserMission) error
	UpdateUserMission(um *models.UserMission) error
	// Seasons
	GetActiveSeason() (*models.Season, error)
	GetSeasonXP(userID, seasonID uint64) (*models.SeasonXP, error)
	UpsertSeasonXP(sxp *models.SeasonXP) error
	GetSeasonLeaderboard(seasonID uint64, page, perPage int) ([]models.SeasonXP, int64, error)
}

type gamificationRepository struct{ db *gorm.DB }

func NewGamificationRepository(db *gorm.DB) GamificationRepository {
	return &gamificationRepository{db: db}
}

// ─── XP ────────────────────────────────────────────────────────────────────

func (r *gamificationRepository) GetUserXP(userID uint64) (*models.UserXP, error) {
	var xp models.UserXP
	err := r.db.Where("user_id = ?", userID).First(&xp).Error
	return &xp, err
}

func (r *gamificationRepository) UpsertUserXP(xp *models.UserXP) error {
	return r.db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "user_id"}},
		DoUpdates: clause.AssignmentColumns([]string{"total_xp", "current_level", "updated_at"}),
	}).Create(xp).Error
}

func (r *gamificationRepository) GetDailyXPLog(userID uint64, source string, date time.Time) (*models.DailyXPLog, error) {
	var log models.DailyXPLog
	err := r.db.Where("user_id = ? AND source = ? AND log_date = ?",
		userID, source, date.Format("2006-01-02")).First(&log).Error
	return &log, err
}

func (r *gamificationRepository) CreateDailyXPLog(l *models.DailyXPLog) error {
	return r.db.Create(l).Error
}

// ─── Badges ────────────────────────────────────────────────────────────────

func (r *gamificationRepository) GetAllBadges() ([]models.Badge, error) {
	var badges []models.Badge
	err := r.db.Order("name ASC").Find(&badges).Error
	return badges, err
}

func (r *gamificationRepository) GetBadgeBySlug(slug string) (*models.Badge, error) {
	var badge models.Badge
	err := r.db.Where("slug = ?", slug).First(&badge).Error
	return &badge, err
}

func (r *gamificationRepository) GetUserBadges(userID uint64) ([]models.UserBadge, error) {
	var ubs []models.UserBadge
	err := r.db.Preload("Badge").Where("user_id = ?", userID).Find(&ubs).Error
	return ubs, err
}

func (r *gamificationRepository) HasBadge(userID, badgeID uint64) (bool, error) {
	var count int64
	err := r.db.Model(&models.UserBadge{}).
		Where("user_id = ? AND badge_id = ?", userID, badgeID).Count(&count).Error
	return count > 0, err
}

func (r *gamificationRepository) AwardBadge(userID, badgeID uint64) error {
	return r.db.Clauses(clause.OnConflict{DoNothing: true}).
		Create(&models.UserBadge{UserID: userID, BadgeID: badgeID}).Error
}

// ─── Missions ──────────────────────────────────────────────────────────────

func (r *gamificationRepository) GetActiveMissions() ([]models.Mission, error) {
	var missions []models.Mission
	err := r.db.Where("is_active = true").Find(&missions).Error
	return missions, err
}

func (r *gamificationRepository) GetUserMissions(userID uint64) ([]models.UserMission, error) {
	var ums []models.UserMission
	err := r.db.Preload("Mission").Where("user_id = ?", userID).Find(&ums).Error
	return ums, err
}

func (r *gamificationRepository) GetUserMission(userID, missionID uint64) (*models.UserMission, error) {
	var um models.UserMission
	err := r.db.Where("user_id = ? AND mission_id = ?", userID, missionID).First(&um).Error
	return &um, err
}

func (r *gamificationRepository) UpsertUserMission(um *models.UserMission) error {
	return r.db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "user_id"}, {Name: "mission_id"}},
		DoUpdates: clause.AssignmentColumns([]string{"progress", "status", "completed_at", "claimed_at", "updated_at"}),
	}).Create(um).Error
}

func (r *gamificationRepository) UpdateUserMission(um *models.UserMission) error {
	return r.db.Save(um).Error
}

// ─── Seasons ───────────────────────────────────────────────────────────────

func (r *gamificationRepository) GetActiveSeason() (*models.Season, error) {
	var season models.Season
	err := r.db.Where("is_active = true").First(&season).Error
	return &season, err
}

func (r *gamificationRepository) GetSeasonXP(userID, seasonID uint64) (*models.SeasonXP, error) {
	var sxp models.SeasonXP
	err := r.db.Where("user_id = ? AND season_id = ?", userID, seasonID).First(&sxp).Error
	return &sxp, err
}

func (r *gamificationRepository) UpsertSeasonXP(sxp *models.SeasonXP) error {
	return r.db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "user_id"}, {Name: "season_id"}},
		DoUpdates: clause.AssignmentColumns([]string{"xp", "updated_at"}),
	}).Create(sxp).Error
}

func (r *gamificationRepository) GetSeasonLeaderboard(seasonID uint64, page, perPage int) ([]models.SeasonXP, int64, error) {
	var entries []models.SeasonXP
	var total int64
	q := r.db.Model(&models.SeasonXP{}).Where("season_id = ?", seasonID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Preload("User").Order("xp DESC").Offset(offset).Limit(perPage).Find(&entries).Error
	return entries, total, err
}
