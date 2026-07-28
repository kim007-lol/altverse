package admin

import (
	"strconv"

	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type WithdrawalController struct {
	txSvc services.TransactionService
	db    *gorm.DB
}

func NewWithdrawalController(txSvc services.TransactionService, db *gorm.DB) *WithdrawalController {
	return &WithdrawalController{txSvc: txSvc, db: db}
}

// ListWithdrawals returns withdrawal requests with author name.
// Query param: status = pending | success | rejected (default: all)
func (h *WithdrawalController) ListWithdrawals(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)
	status := c.Query("status")

	type row struct {
		ID            uint64  `gorm:"column:id"             json:"id"`
		UserID        uint64  `gorm:"column:user_id"        json:"user_id"`
		AuthorName    string  `gorm:"column:author_name"    json:"author_name"`
		AmountIDR     float64 `gorm:"column:amount_idr"     json:"amount_idr"`
		BankName      string  `gorm:"column:bank_name"      json:"bank_name"`
		AccountNumber string  `gorm:"column:account_number" json:"account_number"`
		AccountName   string  `gorm:"column:account_name"   json:"account_name"`
		Status        string  `gorm:"column:status"         json:"status"`
		Notes         *string `gorm:"column:notes"          json:"notes"`
		CreatedAt     string  `gorm:"column:created_at"     json:"created_at"`
	}

	query := h.db.Table("trx_withdrawals w").
		Select("w.id, w.user_id, u.name AS author_name, w.amount_idr, w.bank_name, w.account_number, w.account_name, w.status, w.notes, TO_CHAR(w.created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') AS created_at").
		Joins("LEFT JOIN usr_users u ON u.id = w.user_id")

	if status != "" {
		query = query.Where("w.status = ?", status)
	}

	var total int64
	countQ := h.db.Table("trx_withdrawals")
	if status != "" {
		countQ = countQ.Where("status = ?", status)
	}
	countQ.Count(&total)

	var rows []row
	query.Order("w.created_at DESC").
		Offset((page - 1) * perPage).Limit(perPage).
		Scan(&rows)

	helper.Paginated(c, "Withdrawals fetched", rows, page, perPage, total)
}

func (h *WithdrawalController) Process(c *gin.Context) {
	withdrawalID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid withdrawal id", nil)
		return
	}

	var req dto.ProcessWithdrawalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	if err := h.txSvc.ProcessWithdrawal(withdrawalID, req.Approved, req.Notes); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "Withdrawal processed")
}
