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
	// GrantDailyXP atomically adds up to `amount` XP to the (user, source, date)
	// daily log without exceeding dailyCap, and returns the XP actually granted.
	GrantDailyXP(userID uint64, source string, amount, dailyCap int, date time.Time) (granted int, err error)
	// AddUserXP atomically increments a user's cumulative XP and returns the new total.
	AddUserXP(userID uint64, delta int) (newTotalXP int, err error)
	SetUserLevel(userID uint64, level int) error
	// AddSeasonXP atomically increments a user's XP for the given season.
	AddSeasonXP(userID, seasonID uint64, delta int) error
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
	// ClaimMissionReward atomically marks a completed-but-unclaimed mission as
	// claimed; returns false if no row matched (already claimed / not completed).
	ClaimMissionReward(userID, missionID uint64) (claimed bool, err error)
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

// ClaimMissionReward atomically marks a completed-but-unclaimed mission as
// claimed. Returns false when no row matched (already claimed or not yet
// completed), so the caller awards the reward exactly once under a race.
func (r *gamificationRepository) ClaimMissionReward(userID, missionID uint64) (bool, error) {
	res := r.db.Model(&models.UserMission{}).
		Where("user_id = ? AND mission_id = ? AND completed_at IS NOT NULL AND claimed_at IS NULL", userID, missionID).
		Updates(map[string]any{"claimed_at": gorm.Expr("NOW()"), "status": "claimed"})
	if res.Error != nil {
		return false, res.Error
	}
	return res.RowsAffected == 1, nil
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

// GrantDailyXP adds up to `amount` XP to the (user, source, date) daily log
// without exceeding dailyCap (dailyCap <= 0 means unlimited), and returns the
// delta actually granted (0 once the cap is hit). It serialises concurrent
// awards on the same key via a row lock so the cap can't be raced past.
func (r *gamificationRepository) GrantDailyXP(userID uint64, source string, amount, dailyCap int, date time.Time) (int, error) {
	var granted int
	day := date.Format("2006-01-02")
	err := r.db.Transaction(func(tx *gorm.DB) error {
		// Ensure the row exists (idempotent) so it can be locked.
		if err := tx.Exec(`
			INSERT INTO gam_daily_xp_logs (user_id, source, xp_earned, log_date)
			VALUES (?, ?, 0, ?)
			ON CONFLICT (user_id, source, log_date) DO NOTHING`,
			userID, source, day).Error; err != nil {
			return err
		}

		var prev int
		if err := tx.Raw(`
			SELECT xp_earned FROM gam_daily_xp_logs
			WHERE user_id = ? AND source = ? AND log_date = ? FOR UPDATE`,
			userID, source, day).Row().Scan(&prev); err != nil {
			return err
		}

		newVal := prev + amount
		if dailyCap > 0 && newVal > dailyCap {
			newVal = dailyCap
		}
		granted = newVal - prev
		if granted <= 0 {
			return nil
		}
		return tx.Exec(`
			UPDATE gam_daily_xp_logs SET xp_earned = ?
			WHERE user_id = ? AND source = ? AND log_date = ?`,
			newVal, userID, source, day).Error
	})
	return granted, err
}

func (r *gamificationRepository) AddUserXP(userID uint64, delta int) (int, error) {
	var total int
	err := r.db.Raw(`
		INSERT INTO gam_user_xp (user_id, total_xp, current_level, created_at, updated_at)
		VALUES (?, ?, 1, NOW(), NOW())
		ON CONFLICT (user_id)
		DO UPDATE SET total_xp = gam_user_xp.total_xp + EXCLUDED.total_xp, updated_at = NOW()
		RETURNING total_xp`,
		userID, delta,
	).Scan(&total).Error
	return total, err
}

func (r *gamificationRepository) SetUserLevel(userID uint64, level int) error {
	return r.db.Model(&models.UserXP{}).Where("user_id = ?", userID).
		UpdateColumn("current_level", level).Error
}

func (r *gamificationRepository) AddSeasonXP(userID, seasonID uint64, delta int) error {
	return r.db.Exec(`
		INSERT INTO gam_season_xp (user_id, season_id, xp, created_at, updated_at)
		VALUES (?, ?, ?, NOW(), NOW())
		ON CONFLICT (user_id, season_id)
		DO UPDATE SET xp = gam_season_xp.xp + EXCLUDED.xp, updated_at = NOW()`,
		userID, seasonID, delta,
	).Error
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
