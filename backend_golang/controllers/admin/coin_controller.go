package admin

import (
	"fmt"

	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type CoinController struct {
	db      *gorm.DB
	userSvc services.UserService
}

func NewCoinController(db *gorm.DB, userSvc services.UserService) *CoinController {
	return &CoinController{db: db, userSvc: userSvc}
}

// AdjustCoins manually adds or deducts coins for a user.
// Body: {amount: int (positive=add, negative=deduct), reason: string}
func (h *CoinController) AdjustCoins(c *gin.Context) {
	userID := c.Param("id")

	var req struct {
		Amount int    `json:"amount"  binding:"required"`
		Reason string `json:"reason"  binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	// Verify target user exists.
	var targetCoins int
	if err := h.db.Table("usr_users").Select("coins").Where("id = ? AND deleted_at IS NULL", userID).Scan(&targetCoins).Error; err != nil {
		helper.NotFound(c, "user not found")
		return
	}

	adminID := uint64(middleware.GetUserID(c))

	if req.Amount > 0 {
		h.db.Exec("UPDATE usr_users SET coins = coins + ? WHERE id = ?", req.Amount, userID)
	} else {
		deduct := -req.Amount
		if deduct > targetCoins {
			helper.BadRequest(c, "insufficient coins to deduct", nil)
			return
		}
		h.db.Exec("UPDATE usr_users SET coins = coins - ? WHERE id = ?", deduct, userID)
	}

	// Log the adjustment as a transaction record.
	note := fmt.Sprintf("admin_id=%d reason=%s", adminID, req.Reason)
	h.db.Exec(`INSERT INTO trx_transactions
		(user_id, type, status, coins_requested, amount_idr, midtrans_order_id, payment_url, notes, created_at, updated_at)
		VALUES (?, 'manual_adjustment', 'success', ?, 0, ?, '', ?, NOW(), NOW())`,
		userID, req.Amount, fmt.Sprintf("ADM-%s", userID), note,
	)

	var newCoins int
	h.db.Table("usr_users").Select("coins").Where("id = ?", userID).Scan(&newCoins)

	helper.OK(c, "Coins adjusted", gin.H{
		"user_id":    userID,
		"adjustment": req.Amount,
		"new_total":  newCoins,
		"reason":     req.Reason,
	})
}

// GetCoinHistory returns coin transaction history for a user.
func (h *CoinController) GetCoinHistory(c *gin.Context) {
	userID := c.Param("id")

	type txRow struct {
		ID        uint64  `gorm:"column:id"          json:"id"`
		Type      string  `gorm:"column:type"        json:"type"`
		Status    string  `gorm:"column:status"      json:"status"`
		Coins     int     `gorm:"column:coins"       json:"coins"`
		AmountIDR float64 `gorm:"column:amount_idr"  json:"amount_idr"`
		Notes     string  `gorm:"column:notes"       json:"notes"`
		CreatedAt string  `gorm:"column:created_at"  json:"created_at"`
	}

	var rows []txRow
	h.db.Raw(`
		SELECT id, type, status, coins_requested AS coins, amount_idr,
		       COALESCE(notes, '') AS notes,
		       TO_CHAR(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS created_at
		FROM trx_transactions
		WHERE user_id = ?
		ORDER BY created_at DESC LIMIT 50
	`, userID).Scan(&rows)

	helper.OK(c, "Coin history fetched", gin.H{"data": rows})
}
