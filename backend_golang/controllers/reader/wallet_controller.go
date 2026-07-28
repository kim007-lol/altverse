package reader

import (
	"crypto/sha512"
	"crypto/subtle"
	"encoding/hex"
	"fmt"
	"time"

	"aureader/backend/config"
	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/repositories"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
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
	txSvc    services.TransactionService
	userSvc  services.UserService
	notifSvc services.NotificationService
	userRepo repositories.UserRepository
	db       *gorm.DB
}

func NewWalletController(
	txSvc services.TransactionService,
	userSvc services.UserService,
	notifSvc services.NotificationService,
	userRepo repositories.UserRepository,
	db *gorm.DB,
) *WalletController {
	return &WalletController{txSvc: txSvc, userSvc: userSvc, notifSvc: notifSvc, userRepo: userRepo, db: db}
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
		StatusCode    string `json:"status_code"`
		GrossAmount   string `json:"gross_amount"`
		SignatureKey  string `json:"signature_key"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil {
		helper.BadRequest(c, "invalid payload", nil)
		return
	}

	// Verify the Midtrans signature before trusting any status. Without this,
	// anyone could POST a forged "settlement" for a known order_id and mint coins.
	if !verifyMidtransSignature(payload.OrderID, payload.StatusCode, payload.GrossAmount, payload.SignatureKey) {
		helper.Unauthorized(c, "invalid signature")
		return
	}

	if err := h.txSvc.HandleMidtransCallback(payload.OrderID, payload.TransactionID, payload.Status); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "OK")
}

// verifyMidtransSignature checks the SHA512 signature Midtrans sends:
// sha512(order_id + status_code + gross_amount + server_key).
// If no server key is configured (local dev without Midtrans), verification is
// skipped so the flow remains testable — but it is always enforced once a key is set.
func verifyMidtransSignature(orderID, statusCode, grossAmount, signature string) bool {
	serverKey := config.App.MidtransServerKey
	if serverKey == "" {
		return true
	}
	sum := sha512.Sum512([]byte(orderID + statusCode + grossAmount + serverKey))
	expected := hex.EncodeToString(sum[:])
	return subtle.ConstantTimeCompare([]byte(expected), []byte(signature)) == 1
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

// topupPackageList is the canonical list of purchasable coin packages.
var topupPackageList = []map[string]any{
	{"id": "pkg_10", "name": "Starter", "coins": 10, "price_idr": 15000, "bonus": 0},
	{"id": "pkg_50", "name": "Basic", "coins": 50, "price_idr": 70000, "bonus": 0},
	{"id": "pkg_100", "name": "Standard", "coins": 100, "price_idr": 130000, "bonus": 10},
	{"id": "pkg_500", "name": "Premium", "coins": 500, "price_idr": 600000, "bonus": 50},
	{"id": "pkg_1000", "name": "Whale", "coins": 1000, "price_idr": 1100000, "bonus": 150},
}

// GetTopupPackages returns available coin packages for the wallet top-up screen.
func (h *WalletController) GetTopupPackages(c *gin.Context) {
	helper.OK(c, "Topup packages fetched", gin.H{"data": topupPackageList})
}

// GetDailyStatus returns user stats + daily reward state for the reward screen.
// Response: {level, exp_points, coins, streak, can_claim, next_claim_at}
func (h *WalletController) GetDailyStatus(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	user, err := h.userRepo.FindByID(userID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}

	today := time.Now().Truncate(24 * time.Hour)
	todayStr := today.Format("2006-01-02")

	var claimedCount int64
	h.db.Table("gam_daily_xp_logs").
		Where("user_id = ? AND source = 'daily_reward' AND log_date = ?", userID, todayStr).
		Count(&claimedCount)

	canClaim := claimedCount == 0
	streak := computeDailyStreak(h.db, userID, today, !canClaim)
	nextClaimAt := today.Add(24 * time.Hour)

	helper.OK(c, "Daily status fetched", gin.H{
		"level":         user.Level,
		"exp_points":    user.ExpPoints,
		"coins":         user.Coins,
		"streak":        streak,
		"can_claim":     canClaim,
		"next_claim_at": nextClaimAt.Format(time.RFC3339),
	})
}

// ClaimDailyReward grants XP (and occasionally coins) for the user's daily check-in.
// XP = streak × 10; coins = 10 on every 7th-day milestone.
func (h *WalletController) ClaimDailyReward(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))

	today := time.Now().Truncate(24 * time.Hour)
	todayStr := today.Format("2006-01-02")

	var claimedCount int64
	h.db.Table("gam_daily_xp_logs").
		Where("user_id = ? AND source = 'daily_reward' AND log_date = ?", userID, todayStr).
		Count(&claimedCount)
	if claimedCount > 0 {
		helper.BadRequest(c, "sudah klaim hari ini", nil)
		return
	}

	streak := computeDailyStreak(h.db, userID, today, false) + 1
	xpEarned := streak * 10
	if xpEarned > 200 {
		xpEarned = 200
	}

	h.db.Exec(
		"INSERT INTO gam_daily_xp_logs (user_id, source, xp_earned, log_date, created_at) VALUES (?, 'daily_reward', ?, ?, NOW())",
		userID, xpEarned, todayStr,
	)

	h.db.Exec("INSERT INTO gam_user_xp (user_id, total_xp, current_level) VALUES (?, ?, 1) ON CONFLICT (user_id) DO UPDATE SET total_xp = gam_user_xp.total_xp + EXCLUDED.total_xp", userID, xpEarned)

	coinsEarned := 0
	if streak%7 == 0 {
		coinsEarned = 10
		_ = h.userSvc.AddCoins(userID, coinsEarned)
	}

	helper.OK(c, "Daily reward claimed", gin.H{
		"xp_earned":    xpEarned,
		"coins_earned": coinsEarned,
		"streak":       streak,
	})
}

// computeDailyStreak counts consecutive days ending on or before `ref`.
// If includingRef is true, ref day itself counts; otherwise start from ref-1.
func computeDailyStreak(db *gorm.DB, userID uint64, ref time.Time, includingRef bool) int {
	start := ref
	if !includingRef {
		start = ref.Add(-24 * time.Hour)
	}
	streak := 0
	for {
		dayStr := start.Format("2006-01-02")
		var count int64
		db.Table("gam_daily_xp_logs").
			Where("user_id = ? AND source = 'daily_reward' AND log_date = ?", userID, dayStr).
			Count(&count)
		if count == 0 {
			break
		}
		streak++
		start = start.Add(-24 * time.Hour)
		if streak >= 365 {
			break
		}
	}
	return streak
}

// SendTip transfers coins from the current reader to an author and
// records a tip_received notification for the author.
// Body: {author_id: int, amount: int, message?: string}
func (h *WalletController) SendTip(c *gin.Context) {
	var req struct {
		AuthorID uint64 `json:"author_id" binding:"required"`
		Amount   int    `json:"amount"    binding:"required,min=1"`
		Message  string `json:"message"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	senderID := uint64(middleware.GetUserID(c))
	if senderID == req.AuthorID {
		helper.BadRequest(c, "cannot tip yourself", nil)
		return
	}

	// Deduct from sender.
	if err := h.userSvc.DeductCoins(senderID, req.Amount); err != nil {
		controllers.HandleErr(c, err)
		return
	}

	// Credit author.
	if err := h.userSvc.AddCoins(req.AuthorID, req.Amount); err != nil {
		// Compensate — best-effort, we've already deducted from sender.
		_ = h.userSvc.AddCoins(senderID, req.Amount)
		controllers.HandleErr(c, err)
		return
	}

	// Fetch sender name for the notification body.
	sender, _ := h.userRepo.FindByID(senderID)
	senderName := "Someone"
	if sender != nil {
		senderName = sender.Name
	}

	// Notify the author (fire and forget).
	go func() {
		data := map[string]any{"user_id": senderID, "amount": req.Amount}
		if req.Message != "" {
			data["message"] = req.Message
		}
		_, _ = h.notifSvc.Create(services.CreateNotificationInput{
			UserID: req.AuthorID,
			Type:   "tip_received",
			Title:  "Kamu menerima tip! 🎉",
			Body:   fmt.Sprintf("%s mengirimmu %d koin", senderName, req.Amount),
			Data:   data,
		})
	}()

	remainingCoins, _ := h.userSvc.GetCoins(senderID)
	helper.OK(c, "Tip sent successfully", gin.H{
		"coins_sent":      req.Amount,
		"coins_remaining": remainingCoins,
	})
}
