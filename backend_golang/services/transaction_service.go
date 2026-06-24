package services

import (
	"aureader/backend/errorhandler"
	"aureader/backend/models"
	"aureader/backend/repositories"
)

type CreateTopUpInput struct {
	CoinsRequested int
	AmountIDR      float64
	OrderID        string
	PaymentURL     string
}

type WithdrawalInput struct {
	AmountIDR     float64
	BankName      string
	AccountNumber string
	AccountName   string
}

type TransactionService interface {
	GetHistory(userID uint64, page, perPage int) ([]models.Transaction, int64, error)
	CreateTopUp(userID uint64, input CreateTopUpInput) (*models.TopUp, error)
	HandleMidtransCallback(orderID, transactionID, status string) error
	RequestWithdrawal(userID uint64, input WithdrawalInput) (*models.Withdrawal, error)
	GetWithdrawals(userID uint64, page, perPage int) ([]models.Withdrawal, int64, error)
	GetPendingWithdrawals(page, perPage int) ([]models.Withdrawal, int64, error)
	ProcessWithdrawal(withdrawalID uint64, approved bool, notes string) error
}

type transactionService struct {
	txRepo   repositories.TransactionRepository
	userRepo repositories.UserRepository
}

func NewTransactionService(txRepo repositories.TransactionRepository, userRepo repositories.UserRepository) TransactionService {
	return &transactionService{txRepo: txRepo, userRepo: userRepo}
}

func (s *transactionService) GetHistory(userID uint64, page, perPage int) ([]models.Transaction, int64, error) {
	return s.txRepo.FindTransactionsByUserID(userID, page, perPage)
}

func (s *transactionService) CreateTopUp(userID uint64, input CreateTopUpInput) (*models.TopUp, error) {
	payURL := input.PaymentURL
	topup := &models.TopUp{
		UserID:          userID,
		CoinsRequested:  input.CoinsRequested,
		AmountIDR:       input.AmountIDR,
		MidtransOrderID: input.OrderID,
		PaymentURL:      &payURL,
		Status:          "pending",
	}
	if err := s.txRepo.CreateTopUp(topup); err != nil {
		return nil, errorhandler.NewInternalError("failed to create top-up")
	}
	return topup, nil
}

func (s *transactionService) HandleMidtransCallback(orderID, transactionID, status string) error {
	topup, err := s.txRepo.FindTopUpByOrderID(orderID)
	if err != nil {
		return errorhandler.NewNotFound("top-up order not found")
	}

	switch status {
	case "settlement", "capture":
		// Atomic + idempotent: credits exactly once even under duplicate webhooks.
		if _, err := s.txRepo.SettleTopUp(orderID, transactionID); err != nil {
			return errorhandler.NewInternalError("failed to settle top-up")
		}
	case "cancel", "deny", "expire":
		if topup.Status == "success" {
			return nil // never downgrade an already-credited order
		}
		topup.Status = "failed"
		topup.MidtransTransactionID = &transactionID
		_ = s.txRepo.UpdateTopUp(topup)
	}

	return nil
}

func (s *transactionService) RequestWithdrawal(userID uint64, input WithdrawalInput) (*models.Withdrawal, error) {
	w := &models.Withdrawal{
		UserID:        userID,
		AmountIDR:     input.AmountIDR,
		BankName:      input.BankName,
		AccountNumber: input.AccountNumber,
		AccountName:   input.AccountName,
		Status:        "pending",
	}
	if err := s.txRepo.CreateWithdrawal(w); err != nil {
		return nil, errorhandler.NewInternalError("failed to request withdrawal")
	}
	return w, nil
}

func (s *transactionService) GetWithdrawals(userID uint64, page, perPage int) ([]models.Withdrawal, int64, error) {
	return s.txRepo.FindWithdrawalsByUserID(userID, page, perPage)
}

func (s *transactionService) GetPendingWithdrawals(page, perPage int) ([]models.Withdrawal, int64, error) {
	return s.txRepo.FindPendingWithdrawals(page, perPage)
}

func (s *transactionService) ProcessWithdrawal(withdrawalID uint64, approved bool, notes string) error {
	// Atomic state transition guards against double-processing (paying out twice).
	processed, err := s.txRepo.ProcessWithdrawal(withdrawalID, approved, notes)
	if err != nil {
		return errorhandler.NewInternalError("failed to process withdrawal")
	}
	if !processed {
		return errorhandler.NewConflict("withdrawal not found or already processed")
	}
	return nil
}
