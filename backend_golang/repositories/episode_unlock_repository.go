package repositories

import (
	"errors"

	"aureader/backend/models"

	"gorm.io/gorm"
)

// Repo-level sentinel errors the service maps to HTTP responses.
var (
	ErrInsufficientCoins = errors.New("insufficient coins")
	ErrAlreadyUnlocked   = errors.New("episode already unlocked")
)

// authorRoyaltyPercent is the share of an unlock price credited to the author;
// the remainder is the platform fee.
const authorRoyaltyPercent = 80

type EpisodeUnlockRepository interface {
	IsUnlocked(userID, episodeID uint64) (bool, error)
	ListByUser(userID uint64, page, perPage int) ([]models.EpisodeUnlock, int64, error)
	// Unlock atomically debits the reader, credits the author their royalty,
	// records the unlock, and writes both ledger entries in one transaction.
	Unlock(userID, episodeID, authorID uint64, priceCoins int) error
}

type episodeUnlockRepository struct{ db *gorm.DB }

func NewEpisodeUnlockRepository(db *gorm.DB) EpisodeUnlockRepository {
	return &episodeUnlockRepository{db: db}
}

func (r *episodeUnlockRepository) IsUnlocked(userID, episodeID uint64) (bool, error) {
	var count int64
	err := r.db.Model(&models.EpisodeUnlock{}).
		Where("user_id = ? AND episode_id = ?", userID, episodeID).Count(&count).Error
	return count > 0, err
}

func (r *episodeUnlockRepository) ListByUser(userID uint64, page, perPage int) ([]models.EpisodeUnlock, int64, error) {
	var unlocks []models.EpisodeUnlock
	var total int64
	q := r.db.Model(&models.EpisodeUnlock{}).Where("user_id = ?", userID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Preload("Episode").Order("created_at DESC").Offset(offset).Limit(perPage).Find(&unlocks).Error
	return unlocks, total, err
}

func (r *episodeUnlockRepository) Unlock(userID, episodeID, authorID uint64, priceCoins int) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// 1. Record the unlock first — the unique constraint fails fast on a
		//    double-purchase before any coins move.
		unlock := &models.EpisodeUnlock{UserID: userID, EpisodeID: episodeID, CoinsSpent: priceCoins}
		if err := tx.Create(unlock).Error; err != nil {
			if errors.Is(err, gorm.ErrDuplicatedKey) {
				return ErrAlreadyUnlocked
			}
			return err
		}

		// 2. Debit the reader only if the balance covers the price (atomic guard).
		debit := tx.Model(&models.User{}).
			Where("id = ? AND coins >= ?", userID, priceCoins).
			UpdateColumn("coins", gorm.Expr("coins - ?", priceCoins))
		if debit.Error != nil {
			return debit.Error
		}
		if debit.RowsAffected == 0 {
			return ErrInsufficientCoins
		}

		// 3. Credit the author their royalty share.
		authorShare := priceCoins * authorRoyaltyPercent / 100
		if authorShare > 0 {
			if err := tx.Model(&models.User{}).Where("id = ?", authorID).
				UpdateColumn("coins", gorm.Expr("coins + ?", authorShare)).Error; err != nil {
				return err
			}
		}

		// 4. Write the ledger entries (reader purchase, author reward).
		readerDesc := "Unlock episode"
		authorDesc := "Episode sale royalty"
		entries := []models.Transaction{
			{UserID: userID, Type: "purchase", Coins: -priceCoins, Description: &readerDesc},
			{UserID: authorID, Type: "reward", Coins: authorShare, Description: &authorDesc},
		}
		return tx.Create(&entries).Error
	})
}
