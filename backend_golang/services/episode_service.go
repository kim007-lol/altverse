package services

import (
	"aureader/backend/errorhandler"
	"aureader/backend/models"
	"aureader/backend/repositories"
)

type CreateEpisodeInput struct {
	Title         string
	EpisodeNumber float64
	PriceCoins    int
	ImageURLs     []string
}

type UpdateEpisodeInput struct {
	Title         *string
	EpisodeNumber *float64
	PriceCoins    *int
	Status        *string
	ImageURLs     []string
}

type EpisodeService interface {
	GetByID(id uint64) (*models.Episode, error)
	ListBySeries(seriesID uint64, onlyPublished bool, page, perPage int) ([]models.Episode, int64, error)
	GetPages(episodeID uint64) ([]models.Page, error)
	Create(seriesID, authorID uint64, input CreateEpisodeInput) (*models.Episode, error)
	Update(id, authorID uint64, input UpdateEpisodeInput) (*models.Episode, error)
	Publish(id, authorID uint64) error
	Delete(id, authorID uint64) error
}

type episodeService struct {
	episodeRepo repositories.EpisodeRepository
	seriesRepo  repositories.SeriesRepository
}

func NewEpisodeService(episodeRepo repositories.EpisodeRepository, seriesRepo repositories.SeriesRepository) EpisodeService {
	return &episodeService{episodeRepo: episodeRepo, seriesRepo: seriesRepo}
}

func (s *episodeService) GetByID(id uint64) (*models.Episode, error) {
	ep, err := s.episodeRepo.FindByID(id)
	if err != nil {
		return nil, errorhandler.NewNotFound("episode not found")
	}
	return ep, nil
}

func (s *episodeService) ListBySeries(seriesID uint64, onlyPublished bool, page, perPage int) ([]models.Episode, int64, error) {
	if onlyPublished {
		return s.episodeRepo.FindPublishedBySeriesID(seriesID, page, perPage)
	}
	return s.episodeRepo.FindBySeriesID(seriesID, page, perPage)
}

func (s *episodeService) GetPages(episodeID uint64) ([]models.Page, error) {
	return s.episodeRepo.FindPagesByEpisodeID(episodeID)
}

func (s *episodeService) Create(seriesID, authorID uint64, input CreateEpisodeInput) (*models.Episode, error) {
	series, err := s.seriesRepo.FindByID(seriesID)
	if err != nil {
		return nil, errorhandler.NewNotFound("series not found")
	}
	if series.AuthorID != authorID {
		return nil, errorhandler.NewForbidden("")
	}

	ep := &models.Episode{
		SeriesID:      seriesID,
		Title:         input.Title,
		EpisodeNumber: input.EpisodeNumber,
		PriceCoins:    input.PriceCoins,
		Status:        "draft",
	}
	if err := s.episodeRepo.Create(ep); err != nil {
		return nil, errorhandler.NewInternalError("failed to create episode")
	}

	if len(input.ImageURLs) > 0 {
		pages := make([]models.Page, len(input.ImageURLs))
		for i, url := range input.ImageURLs {
			pages[i] = models.Page{EpisodeID: ep.ID, PageNumber: i + 1, ImageURL: url}
		}
		if err := s.episodeRepo.CreatePages(pages); err != nil {
			return nil, errorhandler.NewInternalError("failed to create pages")
		}
	}

	return s.episodeRepo.FindByID(ep.ID)
}

func (s *episodeService) Update(id, authorID uint64, input UpdateEpisodeInput) (*models.Episode, error) {
	ep, err := s.episodeRepo.FindByID(id)
	if err != nil {
		return nil, errorhandler.NewNotFound("episode not found")
	}

	series, err := s.seriesRepo.FindByID(ep.SeriesID)
	if err != nil || series.AuthorID != authorID {
		return nil, errorhandler.NewForbidden("")
	}

	if input.Title != nil {
		ep.Title = *input.Title
	}
	if input.EpisodeNumber != nil {
		ep.EpisodeNumber = *input.EpisodeNumber
	}
	if input.PriceCoins != nil {
		ep.PriceCoins = *input.PriceCoins
	}
	if input.Status != nil {
		ep.Status = *input.Status
	}

	if err := s.episodeRepo.Update(ep); err != nil {
		return nil, errorhandler.NewInternalError("failed to update episode")
	}

	if len(input.ImageURLs) > 0 {
		pages := make([]models.Page, len(input.ImageURLs))
		for i, url := range input.ImageURLs {
			pages[i] = models.Page{EpisodeID: ep.ID, PageNumber: i + 1, ImageURL: url}
		}
		if err := s.episodeRepo.ReplacePages(ep.ID, pages); err != nil {
			return nil, errorhandler.NewInternalError("failed to update pages")
		}
	}

	return s.episodeRepo.FindByID(ep.ID)
}

func (s *episodeService) Publish(id, authorID uint64) error {
	ep, err := s.episodeRepo.FindByID(id)
	if err != nil {
		return errorhandler.NewNotFound("episode not found")
	}
	series, err := s.seriesRepo.FindByID(ep.SeriesID)
	if err != nil || series.AuthorID != authorID {
		return errorhandler.NewForbidden("")
	}
	ep.Status = "published"
	return s.episodeRepo.Update(ep)
}

func (s *episodeService) Delete(id, authorID uint64) error {
	ep, err := s.episodeRepo.FindByID(id)
	if err != nil {
		return errorhandler.NewNotFound("episode not found")
	}
	series, err := s.seriesRepo.FindByID(ep.SeriesID)
	if err != nil || series.AuthorID != authorID {
		return errorhandler.NewForbidden("")
	}
	return s.episodeRepo.SoftDelete(id)
}
