package repositories

import (
	"aureader/backend/models"

	"gorm.io/gorm"
)

type TransactionRepository interface {
	CreateTransaction(tx *models.Transaction) error
	FindTransactionsByUserID(userID uint64, page, perPage int) ([]models.Transaction, int64, error)
	CreateTopUp(topup *models.TopUp) error
	FindTopUpByOrderID(orderID string) (*models.TopUp, error)
	UpdateTopUp(topup *models.TopUp) error
	// SettleTopUp flips a pending top-up to success and credits the user's coins
	// atomically and idempotently. Returns true only when this call performed the
	// credit (false if a prior/concurrent webhook already settled it).
	SettleTopUp(orderID, transactionID string) (credited bool, err error)
	CreateWithdrawal(w *models.Withdrawal) error
	FindWithdrawalsByUserID(userID uint64, page, perPage int) ([]models.Withdrawal, int64, error)
	UpdateWithdrawal(w *models.Withdrawal) error
	// ProcessWithdrawal atomically transitions a pending withdrawal to its final
	// state. Returns false when the row was not pending (already processed), so
	// callers can reject double-processing instead of paying out twice.
	ProcessWithdrawal(id uint64, approved bool, notes string) (processed bool, err error)
	FindWithdrawalByID(id uint64) (*models.Withdrawal, error)
	FindPendingWithdrawals(page, perPage int) ([]models.Withdrawal, int64, error)
}

type transactionRepository struct{ db *gorm.DB }

func NewTransactionRepository(db *gorm.DB) TransactionRepository {
	return &transactionRepository{db: db}
}

func (r *transactionRepository) CreateTransaction(tx *models.Transaction) error {
	return r.db.Create(tx).Error
}

func (r *transactionRepository) FindTransactionsByUserID(userID uint64, page, perPage int) ([]models.Transaction, int64, error) {
	var txs []models.Transaction
	var total int64
	q := r.db.Model(&models.Transaction{}).Where("user_id = ?", userID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Order("created_at DESC").Offset(offset).Limit(perPage).Find(&txs).Error
	return txs, total, err
}

func (r *transactionRepository) CreateTopUp(topup *models.TopUp) error {
	return r.db.Create(topup).Error
}

func (r *transactionRepository) FindTopUpByOrderID(orderID string) (*models.TopUp, error) {
	var topup models.TopUp
	err := r.db.Where("midtrans_order_id = ?", orderID).First(&topup).Error
	return &topup, err
}

func (r *transactionRepository) UpdateTopUp(topup *models.TopUp) error {
	return r.db.Save(topup).Error
}

func (r *transactionRepository) SettleTopUp(orderID, transactionID string) (bool, error) {
	var credited bool
	err := r.db.Transaction(func(tx *gorm.DB) error {
		// Atomic state transition: only the first caller flips pending -> success,
		// so duplicate/concurrent webhooks can't double-credit.
		res := tx.Model(&models.TopUp{}).
			Where("midtrans_order_id = ? AND status <> 'success'", orderID).
			Updates(map[string]any{
				"status":                  "success",
				"midtrans_transaction_id": transactionID,
				"paid_at":                 gorm.Expr("NOW()"),
			})
		if res.Error != nil {
			return res.Error
		}
		if res.RowsAffected == 0 {
			return nil // already settled — idempotent no-op
		}

		var topup models.TopUp
		if err := tx.Where("midtrans_order_id = ?", orderID).First(&topup).Error; err != nil {
			return err
		}

		// Credit coins with an atomic increment (no read-modify-write race).
		if err := tx.Model(&models.User{}).Where("id = ?", topup.UserID).
			UpdateColumn("coins", gorm.Expr("coins + ?", topup.CoinsRequested)).Error; err != nil {
			return err
		}

		ref := orderID
		if err := tx.Create(&models.Transaction{
			UserID:      topup.UserID,
			Type:        "topup",
			Coins:       topup.CoinsRequested,
			AmountIDR:   topup.AmountIDR,
			ReferenceID: &ref,
		}).Error; err != nil {
			return err
		}
		credited = true
		return nil
	})
	return credited, err
}

func (r *transactionRepository) CreateWithdrawal(w *models.Withdrawal) error {
	return r.db.Create(w).Error
}

func (r *transactionRepository) FindWithdrawalsByUserID(userID uint64, page, perPage int) ([]models.Withdrawal, int64, error) {
	var withdrawals []models.Withdrawal
	var total int64
	q := r.db.Model(&models.Withdrawal{}).Where("user_id = ?", userID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Order("created_at DESC").Offset(offset).Limit(perPage).Find(&withdrawals).Error
	return withdrawals, total, err
}

func (r *transactionRepository) UpdateWithdrawal(w *models.Withdrawal) error {
	return r.db.Save(w).Error
}

func (r *transactionRepository) ProcessWithdrawal(id uint64, approved bool, notes string) (bool, error) {
	status := "failed"
	if approved {
		status = "success"
	}
	updates := map[string]any{
		"status":       status,
		"processed_at": gorm.Expr("NOW()"),
	}
	if notes != "" {
		updates["notes"] = notes
	}
	// Conditional transition: only a still-pending row is updated, so a second
	// call (double-click / retry) affects zero rows and is reported as not processed.
	res := r.db.Model(&models.Withdrawal{}).
		Where("id = ? AND status = 'pending'", id).
		Updates(updates)
	if res.Error != nil {
		return false, res.Error
	}
	return res.RowsAffected == 1, nil
}

func (r *transactionRepository) FindWithdrawalByID(id uint64) (*models.Withdrawal, error) {
	var w models.Withdrawal
	err := r.db.Preload("User").First(&w, id).Error
	return &w, err
}

func (r *transactionRepository) FindPendingWithdrawals(page, perPage int) ([]models.Withdrawal, int64, error) {
	var withdrawals []models.Withdrawal
	var total int64
	q := r.db.Model(&models.Withdrawal{}).Where("status = 'pending'")
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Preload("User").Order("created_at ASC").Offset(offset).Limit(perPage).Find(&withdrawals).Error
	return withdrawals, total, err
}
