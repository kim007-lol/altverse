package reader

import (
	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
)

type ProfileController struct {
	userSvc services.UserService
}

func NewProfileController(userSvc services.UserService) *ProfileController {
	return &ProfileController{userSvc: userSvc}
}

func (h *ProfileController) GetProfile(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	user, err := h.userSvc.GetProfile(userID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Profile fetched", user)
}

func (h *ProfileController) UpdateProfile(c *gin.Context) {
	var req dto.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	userID := uint64(middleware.GetUserID(c))
	user, err := h.userSvc.UpdateProfile(userID, services.UpdateProfileInput{
		Name:            req.Name,
		PenName:         req.PenName,
		Bio:             req.Bio,
		ThemePreference: req.ThemePreference,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Profile updated", user)
}

// Me is the auth/me alias — returns the authenticated user's profile.
// Enriched payload (series_count, badges, tier, etc.) lands in Fase B.
func (h *ProfileController) Me(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	user, err := h.userSvc.GetProfile(userID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "User fetched", user)
}

func (h *ProfileController) GetWallet(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	coins, err := h.userSvc.GetCoins(userID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Wallet fetched", gin.H{"coins": coins})
}
