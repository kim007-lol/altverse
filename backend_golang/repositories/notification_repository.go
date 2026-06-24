package repositories

import (
	"time"

	"aureader/backend/models"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type NotificationRepository interface {
	Create(n *models.Notification) error
	ListByUser(userID uint64, page, perPage int) ([]models.Notification, int64, error)
	CountUnread(userID uint64) (int64, error)
	MarkRead(id, userID uint64) (int64, error)
	MarkAllRead(userID uint64) error
	DeleteReadOlderThan(userID uint64, before time.Time) (int64, error)

	ListPreferences(userID uint64) ([]models.NotificationPreference, error)
	UpsertPreference(pref *models.NotificationPreference) error
}

type notificationRepository struct{ db *gorm.DB }

func NewNotificationRepository(db *gorm.DB) NotificationRepository {
	return &notificationRepository{db: db}
}

func (r *notificationRepository) Create(n *models.Notification) error {
	return r.db.Create(n).Error
}

func (r *notificationRepository) ListByUser(userID uint64, page, perPage int) ([]models.Notification, int64, error) {
	var (
		items []models.Notification
		total int64
	)
	base := r.db.Model(&models.Notification{}).Where("user_id = ?", userID)
	if err := base.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	err := base.
		Order("created_at DESC").
		Offset((page - 1) * perPage).
		Limit(perPage).
		Find(&items).Error
	return items, total, err
}

func (r *notificationRepository) CountUnread(userID uint64) (int64, error) {
	var count int64
	err := r.db.Model(&models.Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Count(&count).Error
	return count, err
}

// MarkRead flips a single notification to read, scoped to its owner.
// Returns the number of rows affected (0 = not found or not owned).
func (r *notificationRepository) MarkRead(id, userID uint64) (int64, error) {
	now := time.Now()
	res := r.db.Model(&models.Notification{}).
		Where("id = ? AND user_id = ? AND is_read = ?", id, userID, false).
		Updates(map[string]any{"is_read": true, "read_at": now})
	return res.RowsAffected, res.Error
}

func (r *notificationRepository) MarkAllRead(userID uint64) error {
	now := time.Now()
	return r.db.Model(&models.Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Updates(map[string]any{"is_read": true, "read_at": now}).Error
}

func (r *notificationRepository) DeleteReadOlderThan(userID uint64, before time.Time) (int64, error) {
	res := r.db.
		Where("user_id = ? AND is_read = ? AND created_at < ?", userID, true, before).
		Delete(&models.Notification{})
	return res.RowsAffected, res.Error
}

func (r *notificationRepository) ListPreferences(userID uint64) ([]models.NotificationPreference, error) {
	var prefs []models.NotificationPreference
	err := r.db.Where("user_id = ?", userID).Find(&prefs).Error
	return prefs, err
}

// UpsertPreference inserts or updates a preference row keyed by (user_id, notification_type).
func (r *notificationRepository) UpsertPreference(pref *models.NotificationPreference) error {
	return r.db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "user_id"}, {Name: "notification_type"}},
		DoUpdates: clause.AssignmentColumns([]string{"enabled", "push_enabled", "email_enabled", "updated_at"}),
	}).Create(pref).Error
}
