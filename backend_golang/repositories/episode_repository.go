package repositories

import (
	"aureader/backend/models"

	"gorm.io/gorm"
)

type EpisodeRepository interface {
	FindByID(id uint64) (*models.Episode, error)
	FindBySeriesID(seriesID uint64, page, perPage int) ([]models.Episode, int64, error)
	FindPublishedBySeriesID(seriesID uint64, page, perPage int) ([]models.Episode, int64, error)
	Create(ep *models.Episode) error
	Update(ep *models.Episode) error
	SoftDelete(id uint64) error
	IncrementViews(id uint64) error
	CreatePages(pages []models.Page) error
	ReplacePages(episodeID uint64, pages []models.Page) error
	FindPagesByEpisodeID(episodeID uint64) ([]models.Page, error)
}

type episodeRepository struct{ db *gorm.DB }

func NewEpisodeRepository(db *gorm.DB) EpisodeRepository {
	return &episodeRepository{db: db}
}

func (r *episodeRepository) FindByID(id uint64) (*models.Episode, error) {
	var ep models.Episode
	err := r.db.Where("id = ? AND deleted_at IS NULL", id).First(&ep).Error
	return &ep, err
}

func (r *episodeRepository) FindBySeriesID(seriesID uint64, page, perPage int) ([]models.Episode, int64, error) {
	var eps []models.Episode
	var total int64
	q := r.db.Model(&models.Episode{}).Where("series_id = ? AND deleted_at IS NULL", seriesID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Order("episode_number ASC").Offset(offset).Limit(perPage).Find(&eps).Error
	return eps, total, err
}

func (r *episodeRepository) FindPublishedBySeriesID(seriesID uint64, page, perPage int) ([]models.Episode, int64, error) {
	var eps []models.Episode
	var total int64
	q := r.db.Model(&models.Episode{}).
		Where("series_id = ? AND status = 'published' AND deleted_at IS NULL", seriesID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Order("episode_number ASC").Offset(offset).Limit(perPage).Find(&eps).Error
	return eps, total, err
}

func (r *episodeRepository) Create(ep *models.Episode) error {
	return r.db.Create(ep).Error
}

func (r *episodeRepository) Update(ep *models.Episode) error {
	return r.db.Save(ep).Error
}

func (r *episodeRepository) SoftDelete(id uint64) error {
	return r.db.Model(&models.Episode{}).Where("id = ?", id).
		Update("deleted_at", gorm.Expr("NOW()")).Error
}

func (r *episodeRepository) IncrementViews(id uint64) error {
	return r.db.Model(&models.Episode{}).Where("id = ?", id).
		UpdateColumn("total_views", gorm.Expr("total_views + 1")).Error
}

func (r *episodeRepository) CreatePages(pages []models.Page) error {
	return r.db.Create(&pages).Error
}

func (r *episodeRepository) ReplacePages(episodeID uint64, pages []models.Page) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("episode_id = ?", episodeID).Delete(&models.Page{}).Error; err != nil {
			return err
		}
		return tx.Create(&pages).Error
	})
}

func (r *episodeRepository) FindPagesByEpisodeID(episodeID uint64) ([]models.Page, error) {
	var pages []models.Page
	err := r.db.Where("episode_id = ?", episodeID).Order("page_number ASC").Find(&pages).Error
	return pages, err
}
