package services

import (
	"aureader/backend/models"
	"aureader/backend/repositories"
)

type UpdateProgressInput struct {
	LastReadPage       int
	ProgressPercentage float64
}

type TrackingService interface {
	UpdateProgress(userID, episodeID uint64, input UpdateProgressInput) error
	GetProgress(userID, episodeID uint64) (*models.ReadingHistory, error)
	GetReadingHistory(userID uint64, page, perPage int) ([]models.ReadingHistory, int64, error)
	LogView(episodeID uint64, userID *uint64, ipAddress string) error
}

type trackingService struct {
	trackingRepo repositories.TrackingRepository
	episodeRepo  repositories.EpisodeRepository
}

func NewTrackingService(trackingRepo repositories.TrackingRepository, episodeRepo repositories.EpisodeRepository) TrackingService {
	return &trackingService{trackingRepo: trackingRepo, episodeRepo: episodeRepo}
}

func (s *trackingService) UpdateProgress(userID, episodeID uint64, input UpdateProgressInput) error {
	history := &models.ReadingHistory{
		UserID:             userID,
		EpisodeID:          episodeID,
		LastReadPage:       input.LastReadPage,
		ProgressPercentage: input.ProgressPercentage,
	}
	return s.trackingRepo.UpsertReadingHistory(history)
}

func (s *trackingService) GetProgress(userID, episodeID uint64) (*models.ReadingHistory, error) {
	return s.trackingRepo.FindReadingHistory(userID, episodeID)
}

func (s *trackingService) GetReadingHistory(userID uint64, page, perPage int) ([]models.ReadingHistory, int64, error) {
	return s.trackingRepo.FindReadingHistoriesByUser(userID, page, perPage)
}

func (s *trackingService) LogView(episodeID uint64, userID *uint64, ipAddress string) error {
	log := &models.ViewLog{
		EpisodeID: episodeID,
		UserID:    userID,
		IPAddress: &ipAddress,
	}
	go func() { _ = s.episodeRepo.IncrementViews(episodeID) }()
	return s.trackingRepo.LogView(log)
}
