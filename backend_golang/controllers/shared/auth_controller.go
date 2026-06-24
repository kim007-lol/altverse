package shared

import (
	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
)

type AuthController struct {
	authSvc services.AuthService
}

func NewAuthController(authSvc services.AuthService) *AuthController {
	return &AuthController{authSvc: authSvc}
}

func (h *AuthController) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	user, pair, err := h.authSvc.Register(services.RegisterInput{
		Name:     req.Name,
		Email:    req.Email,
		Password: req.Password,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}

	helper.Created(c, "Registration successful", gin.H{
		"user":          user,
		"access_token":  pair.AccessToken,
		"refresh_token": pair.RefreshToken,
	})
}

func (h *AuthController) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	user, pair, err := h.authSvc.Login(services.LoginInput{
		Email:    req.Email,
		Password: req.Password,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}

	helper.OK(c, "Login successful", gin.H{
		"user":          user,
		"access_token":  pair.AccessToken,
		"refresh_token": pair.RefreshToken,
	})
}

func (h *AuthController) Refresh(c *gin.Context) {
	var req dto.RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	pair, err := h.authSvc.RefreshTokens(req.RefreshToken)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}

	helper.OK(c, "Token refreshed", gin.H{
		"access_token":  pair.AccessToken,
		"refresh_token": pair.RefreshToken,
	})
}

func (h *AuthController) Logout(c *gin.Context) {
	jti, _ := c.Get("token_jti")
	if jtiStr, ok := jti.(string); ok {
		_ = h.authSvc.Logout(jtiStr)
	}
	helper.NoContent(c, "Logged out successfully")
}

func (h *AuthController) LogoutAll(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	_ = h.authSvc.LogoutAll(userID)
	helper.NoContent(c, "All sessions terminated")
}
