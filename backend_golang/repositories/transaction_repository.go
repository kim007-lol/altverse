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
	CreateWithdrawal(w *models.Withdrawal) error
	FindWithdrawalsByUserID(userID uint64, page, perPage int) ([]models.Withdrawal, int64, error)
	UpdateWithdrawal(w *models.Withdrawal) error
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
