package services

import (
	"errors"
	"fmt"

	"aureader/backend/errorhandler"
	"aureader/backend/models"
	"aureader/backend/repositories"
)

// AccessInfo describes a reader's relationship to a single episode, used by the
// reader read endpoint to decide whether to serve full pages or a locked preview.
type AccessInfo struct {
	IsPremium bool // episode costs coins
	IsOwn     bool // the requesting user is the series author
	Unlocked  bool // the reader has already paid for this episode
	CoinPrice int
}

// HasAccess reports whether the reader may read the full episode content.
func (a AccessInfo) HasAccess() bool {
	return !a.IsPremium || a.IsOwn || a.Unlocked
}

// UnlockResult is returned to the reader after a successful purchase.
type UnlockResult struct {
	CoinsSpent     int `json:"coins_spent"`
	CoinsRemaining int `json:"coins_remaining"`
}

type UnlockService interface {
	GetAccess(userID, episodeID uint64) (*AccessInfo, error)
	Unlock(userID, episodeID uint64) (*UnlockResult, error)
	ListUnlocked(userID uint64, page, perPage int) ([]models.EpisodeUnlock, int64, error)
}

type unlockService struct {
	unlockRepo  repositories.EpisodeUnlockRepository
	episodeRepo repositories.EpisodeRepository
	seriesRepo  repositories.SeriesRepository
	userRepo    repositories.UserRepository
	notifSvc    NotificationService
}

func NewUnlockService(
	unlockRepo repositories.EpisodeUnlockRepository,
	episodeRepo repositories.EpisodeRepository,
	seriesRepo repositories.SeriesRepository,
	userRepo repositories.UserRepository,
	notifSvc NotificationService,
) UnlockService {
	return &unlockService{
		unlockRepo:  unlockRepo,
		episodeRepo: episodeRepo,
		seriesRepo:  seriesRepo,
		userRepo:    userRepo,
		notifSvc:    notifSvc,
	}
}

func (s *unlockService) GetAccess(userID, episodeID uint64) (*AccessInfo, error) {
	ep, err := s.episodeRepo.FindByID(episodeID)
	if err != nil {
		return nil, errorhandler.NewNotFound("episode not found")
	}
	series, err := s.seriesRepo.FindByID(ep.SeriesID)
	if err != nil {
		return nil, errorhandler.NewNotFound("series not found")
	}

	info := &AccessInfo{
		IsPremium: ep.PriceCoins > 0,
		IsOwn:     series.AuthorID == userID,
		CoinPrice: ep.PriceCoins,
	}
	// Only a paying reader needs an unlock lookup; owners and free episodes skip it.
	if info.IsPremium && !info.IsOwn {
		unlocked, err := s.unlockRepo.IsUnlocked(userID, episodeID)
		if err != nil {
			return nil, errorhandler.NewInternalError("failed to check unlock status")
		}
		info.Unlocked = unlocked
	}
	return info, nil
}

func (s *unlockService) Unlock(userID, episodeID uint64) (*UnlockResult, error) {
	ep, err := s.episodeRepo.FindByID(episodeID)
	if err != nil {
		return nil, errorhandler.NewNotFound("episode not found")
	}
	if ep.PriceCoins <= 0 {
		return nil, errorhandler.NewBadRequest("this episode is free")
	}

	series, err := s.seriesRepo.FindByID(ep.SeriesID)
	if err != nil {
		return nil, errorhandler.NewNotFound("series not found")
	}
	if series.AuthorID == userID {
		return nil, errorhandler.NewBadRequest("you cannot unlock your own episode")
	}

	if err := s.unlockRepo.Unlock(userID, episodeID, series.AuthorID, ep.PriceCoins); err != nil {
		switch {
		case errors.Is(err, repositories.ErrAlreadyUnlocked):
			return nil, errorhandler.NewConflict("episode already unlocked")
		case errors.Is(err, repositories.ErrInsufficientCoins):
			return nil, errorhandler.NewInsufficientCoin()
		default:
			return nil, errorhandler.NewInternalError("failed to unlock episode")
		}
	}

	s.notifyAuthor(series.AuthorID, userID, ep)

	remaining := 0
	if reader, err := s.userRepo.FindByID(userID); err == nil {
		remaining = reader.Coins
	}
	return &UnlockResult{CoinsSpent: ep.PriceCoins, CoinsRemaining: remaining}, nil
}

func (s *unlockService) ListUnlocked(userID uint64, page, perPage int) ([]models.EpisodeUnlock, int64, error) {
	return s.unlockRepo.ListByUser(userID, page, perPage)
}

// notifyAuthor raises an episode_unlock notification for the author. Best-effort:
// a notification failure must never fail the purchase.
func (s *unlockService) notifyAuthor(authorID, readerID uint64, ep *models.Episode) {
	if s.notifSvc == nil {
		return
	}
	_, _ = s.notifSvc.Create(CreateNotificationInput{
		UserID: authorID,
		Type:   "episode_unlock",
		Title:  "Episode di-unlock",
		Body:   fmt.Sprintf("Seseorang membuka episode \"%s\" milikmu", ep.Title),
		Data: map[string]any{
			"episode_id": ep.ID,
			"series_id":  ep.SeriesID,
			"reader_id":  readerID,
		},
	})
}
