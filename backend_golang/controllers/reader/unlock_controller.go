package reader

import (
	"strconv"

	"aureader/backend/controllers"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
)

type UnlockController struct {
	unlockSvc services.UnlockService
}

func NewUnlockController(unlockSvc services.UnlockService) *UnlockController {
	return &UnlockController{unlockSvc: unlockSvc}
}

// Unlock buys access to a premium episode with the reader's coins.
func (h *UnlockController) Unlock(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}

	userID := uint64(middleware.GetUserID(c))
	result, err := h.unlockSvc.Unlock(userID, episodeID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Episode unlocked", result)
}

// ListUnlocked returns every episode the reader has purchased.
func (h *UnlockController) ListUnlocked(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	unlocks, total, err := h.unlockSvc.ListUnlocked(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Unlocked episodes fetched", unlocks, page, perPage, total)
}
