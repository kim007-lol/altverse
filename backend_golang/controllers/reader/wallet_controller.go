package reader

import (
	"fmt"
	"time"

	"aureader/backend/config"
	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// coinPriceIDR maps coin package amounts to IDR price.
var coinPriceIDR = map[int]float64{
	10:   15000,
	50:   70000,
	100:  130000,
	500:  600000,
	1000: 1100000,
}

type WalletController struct {
	txSvc   services.TransactionService
	userSvc services.UserService
}

func NewWalletController(txSvc services.TransactionService, userSvc services.UserService) *WalletController {
	return &WalletController{txSvc: txSvc, userSvc: userSvc}
}

func (h *WalletController) GetTransactions(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	txs, total, err := h.txSvc.GetHistory(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Transactions fetched", txs, page, perPage, total)
}

func (h *WalletController) CreateTopUp(c *gin.Context) {
	var req dto.TopUpRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	amountIDR, ok := coinPriceIDR[req.CoinsPackage]
	if !ok {
		helper.BadRequest(c, "invalid coin package", nil)
		return
	}

	userID := uint64(middleware.GetUserID(c))
	orderID := fmt.Sprintf("AU-%s-%d", uuid.NewString()[:8], time.Now().Unix())

	// Payment URL generation would normally call Midtrans SDK here.
	// We store the order and return the URL for the client to redirect.
	paymentURL := fmt.Sprintf("%s/pay/%s", config.App.AppURL, orderID)

	topup, err := h.txSvc.CreateTopUp(userID, services.CreateTopUpInput{
		CoinsRequested: req.CoinsPackage,
		AmountIDR:      amountIDR,
		OrderID:        orderID,
		PaymentURL:     paymentURL,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}

	helper.Created(c, "Top-up created", gin.H{
		"order_id":    topup.MidtransOrderID,
		"payment_url": topup.PaymentURL,
		"amount_idr":  topup.AmountIDR,
		"coins":       topup.CoinsRequested,
	})
}

func (h *WalletController) MidtransWebhook(c *gin.Context) {
	var payload struct {
		OrderID       string `json:"order_id"`
		TransactionID string `json:"transaction_id"`
		Status        string `json:"transaction_status"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil {
		helper.BadRequest(c, "invalid payload", nil)
		return
	}

	if err := h.txSvc.HandleMidtransCallback(payload.OrderID, payload.TransactionID, payload.Status); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "OK")
}

func (h *WalletController) RequestWithdrawal(c *gin.Context) {
	var req dto.WithdrawalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	userID := uint64(middleware.GetUserID(c))
	w, err := h.txSvc.RequestWithdrawal(userID, services.WithdrawalInput{
		AmountIDR:     req.AmountIDR,
		BankName:      req.BankName,
		AccountNumber: req.AccountNumber,
		AccountName:   req.AccountName,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Created(c, "Withdrawal requested", w)
}

func (h *WalletController) GetWithdrawals(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	withdrawals, total, err := h.txSvc.GetWithdrawals(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Withdrawals fetched", withdrawals, page, perPage, total)
}

// GetWalletSummary returns coin balance plus recent transactions in one payload,
// matching the Flutter GET /wallet contract.
func (h *WalletController) GetWalletSummary(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	coins, err := h.userSvc.GetCoins(userID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	page, perPage := controllers.PaginationParams(c)
	txs, total, err := h.txSvc.GetHistory(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Wallet fetched", gin.H{
		"coins":        coins,
		"transactions": txs,
		"total":        total,
		"page":         page,
		"per_page":     perPage,
	})
}

// TopUpStatus lets the client poll whether an order was paid.
func (h *WalletController) TopUpStatus(c *gin.Context) {
	orderID := c.Param("order_id")
	helper.OK(c, "Use the Midtrans webhook to confirm payment", gin.H{"order_id": orderID})
}
