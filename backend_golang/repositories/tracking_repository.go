package repositories

import (
	"aureader/backend/models"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type TrackingRepository interface {
	UpsertReadingHistory(history *models.ReadingHistory) error
	FindReadingHistory(userID, episodeID uint64) (*models.ReadingHistory, error)
	FindReadingHistoriesByUser(userID uint64, page, perPage int) ([]models.ReadingHistory, int64, error)
	LogView(log *models.ViewLog) error
}

type trackingRepository struct{ db *gorm.DB }

func NewTrackingRepository(db *gorm.DB) TrackingRepository {
	return &trackingRepository{db: db}
}

func (r *trackingRepository) UpsertReadingHistory(history *models.ReadingHistory) error {
	return r.db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "user_id"}, {Name: "episode_id"}},
		DoUpdates: clause.AssignmentColumns([]string{"last_read_page", "progress_percentage", "last_read_at", "updated_at"}),
	}).Create(history).Error
}

func (r *trackingRepository) FindReadingHistory(userID, episodeID uint64) (*models.ReadingHistory, error) {
	var h models.ReadingHistory
	err := r.db.Where("user_id = ? AND episode_id = ?", userID, episodeID).First(&h).Error
	return &h, err
}

func (r *trackingRepository) FindReadingHistoriesByUser(userID uint64, page, perPage int) ([]models.ReadingHistory, int64, error) {
	var histories []models.ReadingHistory
	var total int64
	q := r.db.Model(&models.ReadingHistory{}).Where("user_id = ?", userID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Preload("Episode.Series").
		Order("last_read_at DESC").Offset(offset).Limit(perPage).Find(&histories).Error
	return histories, total, err
}

func (r *trackingRepository) LogView(log *models.ViewLog) error {
	return r.db.Create(log).Error
}
