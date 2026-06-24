package services

import (
	"strings"

	"aureader/backend/errorhandler"
	"aureader/backend/models"
	"aureader/backend/repositories"
)

type CreateSeriesInput struct {
	Title    string
	Synopsis *string
	Type     string
	GenreIDs []uint64
}

type UpdateSeriesInput struct {
	Title     *string
	Synopsis  *string
	CoverURL  *string
	BannerURL *string
	Status    *string
	Type      *string
	GenreIDs  []uint64
}

type SeriesService interface {
	GetByID(id uint64) (*models.Series, error)
	GetBySlug(slug string) (*models.Series, error)
	List(filter repositories.SeriesFilter) ([]models.Series, int64, error)
	ListByAuthor(authorID uint64, page, perPage int) ([]models.Series, int64, error)
	Create(authorID uint64, input CreateSeriesInput) (*models.Series, error)
	Update(id, authorID uint64, input UpdateSeriesInput) (*models.Series, error)
	Delete(id, authorID uint64) error
	ListGenres() ([]models.Genre, error)
}

type seriesService struct {
	seriesRepo repositories.SeriesRepository
}

func NewSeriesService(seriesRepo repositories.SeriesRepository) SeriesService {
	return &seriesService{seriesRepo: seriesRepo}
}

func (s *seriesService) GetByID(id uint64) (*models.Series, error) {
	series, err := s.seriesRepo.FindByID(id)
	if err != nil {
		return nil, errorhandler.NewNotFound("series not found")
	}
	return series, nil
}

func (s *seriesService) GetBySlug(slug string) (*models.Series, error) {
	series, err := s.seriesRepo.FindBySlug(slug)
	if err != nil {
		return nil, errorhandler.NewNotFound("series not found")
	}
	return series, nil
}

func (s *seriesService) List(filter repositories.SeriesFilter) ([]models.Series, int64, error) {
	return s.seriesRepo.FindAll(filter)
}

func (s *seriesService) ListByAuthor(authorID uint64, page, perPage int) ([]models.Series, int64, error) {
	return s.seriesRepo.FindByAuthorID(authorID, page, perPage)
}

func (s *seriesService) Create(authorID uint64, input CreateSeriesInput) (*models.Series, error) {
	slug := slugify(input.Title)

	series := &models.Series{
		AuthorID: authorID,
		Title:    input.Title,
		Slug:     slug,
		Synopsis: input.Synopsis,
		Type:     input.Type,
		Status:   "draft",
	}

	if err := s.seriesRepo.Create(series); err != nil {
		return nil, errorhandler.NewInternalError("failed to create series")
	}

	if len(input.GenreIDs) > 0 {
		genres := make([]models.Genre, len(input.GenreIDs))
		for i, id := range input.GenreIDs {
			genres[i] = models.Genre{ID: id}
		}
		_ = s.seriesRepo.SyncGenres(series.ID, genres)
	}

	return s.seriesRepo.FindByID(series.ID)
}

func (s *seriesService) Update(id, authorID uint64, input UpdateSeriesInput) (*models.Series, error) {
	series, err := s.seriesRepo.FindByID(id)
	if err != nil {
		return nil, errorhandler.NewNotFound("series not found")
	}
	if series.AuthorID != authorID {
		return nil, errorhandler.NewForbidden("")
	}

	if input.Title != nil {
		series.Title = *input.Title
		series.Slug = slugify(*input.Title)
	}
	if input.Synopsis != nil {
		series.Synopsis = input.Synopsis
	}
	if input.CoverURL != nil {
		series.CoverURL = input.CoverURL
	}
	if input.BannerURL != nil {
		series.BannerURL = input.BannerURL
	}
	if input.Status != nil {
		series.Status = *input.Status
	}
	if input.Type != nil {
		series.Type = *input.Type
	}

	if err := s.seriesRepo.Update(series); err != nil {
		return nil, errorhandler.NewInternalError("failed to update series")
	}

	if input.GenreIDs != nil {
		genres := make([]models.Genre, len(input.GenreIDs))
		for i, gid := range input.GenreIDs {
			genres[i] = models.Genre{ID: gid}
		}
		_ = s.seriesRepo.SyncGenres(series.ID, genres)
	}

	return s.seriesRepo.FindByID(series.ID)
}

func (s *seriesService) Delete(id, authorID uint64) error {
	series, err := s.seriesRepo.FindByID(id)
	if err != nil {
		return errorhandler.NewNotFound("series not found")
	}
	if series.AuthorID != authorID {
		return errorhandler.NewForbidden("")
	}
	return s.seriesRepo.SoftDelete(id)
}

func (s *seriesService) ListGenres() ([]models.Genre, error) {
	return s.seriesRepo.FindAllGenres()
}

func slugify(s string) string {
	s = strings.ToLower(s)
	s = strings.ReplaceAll(s, " ", "-")
	// Keep only alphanumeric and hyphens
	var b strings.Builder
	for _, r := range s {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' {
			b.WriteRune(r)
		}
	}
	return strings.Trim(b.String(), "-")
}
