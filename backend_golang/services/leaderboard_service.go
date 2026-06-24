package services

import (
	"aureader/backend/errorhandler"
	"aureader/backend/models"
	"aureader/backend/repositories"
)

type LeaderboardService interface {
	GetActiveSeason() (*models.Season, error)
	GetLeaderboard(seasonID uint64, page, perPage int) ([]models.SeasonXP, int64, error)
	GetCurrentLeaderboard(page, perPage int) ([]models.SeasonXP, int64, error)
}

type leaderboardService struct {
	gamRepo repositories.GamificationRepository
}

func NewLeaderboardService(gamRepo repositories.GamificationRepository) LeaderboardService {
	return &leaderboardService{gamRepo: gamRepo}
}

func (s *leaderboardService) GetActiveSeason() (*models.Season, error) {
	season, err := s.gamRepo.GetActiveSeason()
	if err != nil {
		return nil, errorhandler.NewNotFound("no active season")
	}
	return season, nil
}

func (s *leaderboardService) GetLeaderboard(seasonID uint64, page, perPage int) ([]models.SeasonXP, int64, error) {
	return s.gamRepo.GetSeasonLeaderboard(seasonID, page, perPage)
}

func (s *leaderboardService) GetCurrentLeaderboard(page, perPage int) ([]models.SeasonXP, int64, error) {
	season, err := s.gamRepo.GetActiveSeason()
	if err != nil {
		return nil, 0, errorhandler.NewNotFound("no active season")
	}
	return s.gamRepo.GetSeasonLeaderboard(season.ID, page, perPage)
}
