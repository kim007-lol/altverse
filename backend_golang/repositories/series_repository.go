package repositories

import (
	"aureader/backend/models"

	"gorm.io/gorm"
)

type SeriesFilter struct {
	AuthorID *uint64
	Status   string
	Type     string
	GenreID  *uint64
	Search   string
	Page     int
	PerPage  int
}

type SeriesRepository interface {
	FindByID(id uint64) (*models.Series, error)
	FindBySlug(slug string) (*models.Series, error)
	FindAll(filter SeriesFilter) ([]models.Series, int64, error)
	FindByAuthorID(authorID uint64, page, perPage int) ([]models.Series, int64, error)
	Create(series *models.Series) error
	Update(series *models.Series) error
	SoftDelete(id uint64) error
	FindAllGenres() ([]models.Genre, error)
	SyncGenres(seriesID uint64, genres []models.Genre) error
}

type seriesRepository struct{ db *gorm.DB }

func NewSeriesRepository(db *gorm.DB) SeriesRepository {
	return &seriesRepository{db: db}
}

func (r *seriesRepository) FindByID(id uint64) (*models.Series, error) {
	var s models.Series
	err := r.db.Preload("Author").Preload("Genres").
		Where("id = ? AND deleted_at IS NULL", id).First(&s).Error
	return &s, err
}

func (r *seriesRepository) FindBySlug(slug string) (*models.Series, error) {
	var s models.Series
	err := r.db.Preload("Author").Preload("Genres").
		Where("slug = ? AND deleted_at IS NULL", slug).First(&s).Error
	return &s, err
}

func (r *seriesRepository) FindAll(f SeriesFilter) ([]models.Series, int64, error) {
	q := r.db.Model(&models.Series{}).Where("deleted_at IS NULL")

	if f.AuthorID != nil {
		q = q.Where("author_id = ?", *f.AuthorID)
	}
	if f.Status != "" {
		q = q.Where("status = ?", f.Status)
	}
	if f.Type != "" {
		q = q.Where("type = ?", f.Type)
	}
	if f.Search != "" {
		q = q.Where("title ILIKE ?", "%"+f.Search+"%")
	}
	if f.GenreID != nil {
		q = q.Joins("JOIN cnt_series_genres sg ON sg.series_id = cnt_series.id").
			Where("sg.genre_id = ?", *f.GenreID)
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var series []models.Series
	offset := (f.Page - 1) * f.PerPage
	err := q.Preload("Author").Preload("Genres").
		Order("updated_at DESC").Offset(offset).Limit(f.PerPage).Find(&series).Error
	return series, total, err
}

func (r *seriesRepository) FindByAuthorID(authorID uint64, page, perPage int) ([]models.Series, int64, error) {
	return r.FindAll(SeriesFilter{AuthorID: &authorID, Page: page, PerPage: perPage})
}

func (r *seriesRepository) Create(series *models.Series) error {
	return r.db.Create(series).Error
}

func (r *seriesRepository) Update(series *models.Series) error {
	return r.db.Save(series).Error
}

func (r *seriesRepository) SoftDelete(id uint64) error {
	return r.db.Model(&models.Series{}).Where("id = ?", id).
		Update("deleted_at", gorm.Expr("NOW()")).Error
}

func (r *seriesRepository) FindAllGenres() ([]models.Genre, error) {
	var genres []models.Genre
	err := r.db.Order("name ASC").Find(&genres).Error
	return genres, err
}

func (r *seriesRepository) SyncGenres(seriesID uint64, genres []models.Genre) error {
	return r.db.Model(&models.Series{ID: seriesID}).Association("Genres").Replace(genres)
}
