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
	if topup.Status == "success" {
		return nil // idempotent — already processed
	}

	topup.MidtransTransactionID = &transactionID

	switch status {
	case "settlement", "capture":
		topup.Status = "success"
		if err := s.txRepo.UpdateTopUp(topup); err != nil {
			return errorhandler.NewInternalError("failed to update top-up")
		}
		user, err := s.userRepo.FindByID(topup.UserID)
		if err != nil {
			return errorhandler.NewInternalError("user not found")
		}
		user.Coins += topup.CoinsRequested
		if err := s.userRepo.Update(user); err != nil {
			return errorhandler.NewInternalError("failed to credit coins")
		}
		_ = s.txRepo.CreateTransaction(&models.Transaction{
			UserID:      topup.UserID,
			Type:        "topup",
			Coins:       topup.CoinsRequested,
			AmountIDR:   topup.AmountIDR,
			ReferenceID: &orderID,
		})
	case "cancel", "deny", "expire":
		topup.Status = "failed"
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
	w, err := s.txRepo.FindWithdrawalByID(withdrawalID)
	if err != nil {
		return errorhandler.NewNotFound("withdrawal not found")
	}

	if approved {
		w.Status = "success"
	} else {
		w.Status = "failed"
	}
	if notes != "" {
		w.Notes = &notes
	}

	return s.txRepo.UpdateWithdrawal(w)
}
