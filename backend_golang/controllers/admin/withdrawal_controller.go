package admin

import (
	"strconv"

	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
)

type WithdrawalController struct {
	txSvc services.TransactionService
}

func NewWithdrawalController(txSvc services.TransactionService) *WithdrawalController {
	return &WithdrawalController{txSvc: txSvc}
}

func (h *WithdrawalController) ListPending(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)
	withdrawals, total, err := h.txSvc.GetPendingWithdrawals(page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Pending withdrawals fetched", withdrawals, page, perPage, total)
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
