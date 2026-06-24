package services

import (
	"errors"
	"time"

	"aureader/backend/config"
	"aureader/backend/errorhandler"
	"aureader/backend/helper"
	"aureader/backend/models"
	"aureader/backend/repositories"

	"gorm.io/gorm"
)

type RegisterInput struct {
	Name     string
	Email    string
	Password string
}

type LoginInput struct {
	Email    string
	Password string
}

type TokenPair struct {
	AccessToken  string
	RefreshToken string
}

type AuthService interface {
	Register(input RegisterInput) (*models.User, *TokenPair, error)
	Login(input LoginInput) (*models.User, *TokenPair, error)
	RefreshTokens(refreshToken string) (*TokenPair, error)
	Logout(jti string) error
	LogoutAll(userID uint64) error
}

type authService struct {
	userRepo repositories.UserRepository
}

func NewAuthService(userRepo repositories.UserRepository) AuthService {
	return &authService{userRepo: userRepo}
}

func (s *authService) Register(input RegisterInput) (*models.User, *TokenPair, error) {
	_, err := s.userRepo.FindByEmail(input.Email)
	if err == nil {
		return nil, nil, errorhandler.NewConflict("email already registered")
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil, errorhandler.NewInternalError("")
	}

	hashed, err := helper.HashPassword(input.Password)
	if err != nil {
		return nil, nil, errorhandler.NewInternalError("failed to hash password")
	}

	user := &models.User{
		Name:     input.Name,
		Email:    input.Email,
		Password: hashed,
		Role:     "reader",
	}
	if err := s.userRepo.Create(user); err != nil {
		return nil, nil, errorhandler.NewInternalError("failed to create user")
	}

	// Issue a token pair so the client is logged in immediately after register.
	pair, err := s.issueTokenPair(user)
	if err != nil {
		return nil, nil, err
	}
	return user, pair, nil
}

func (s *authService) Login(input LoginInput) (*models.User, *TokenPair, error) {
	user, err := s.userRepo.FindByEmail(input.Email)
	if err != nil {
		return nil, nil, errorhandler.NewUnauthorized("invalid email or password")
	}

	if !helper.CheckPassword(user.Password, input.Password) {
		return nil, nil, errorhandler.NewUnauthorized("invalid email or password")
	}

	pair, err := s.issueTokenPair(user)
	if err != nil {
		return nil, nil, err
	}
	return user, pair, nil
}

func (s *authService) RefreshTokens(refreshTokenStr string) (*TokenPair, error) {
	claims, err := helper.ParseToken(refreshTokenStr)
	if err != nil {
		return nil, errorhandler.NewUnauthorized("invalid refresh token")
	}
	if claims.Type != helper.RefreshToken {
		return nil, errorhandler.NewUnauthorized("invalid token type")
	}

	stored, err := s.userRepo.FindRefreshToken(claims.ID)
	if err != nil {
		return nil, errorhandler.NewUnauthorized("refresh token not found or already used")
	}
	if time.Now().After(stored.ExpiresAt) {
		_ = s.userRepo.DeleteRefreshToken(claims.ID)
		return nil, errorhandler.NewUnauthorized("refresh token expired")
	}

	user, err := s.userRepo.FindByID(stored.UserID)
	if err != nil {
		return nil, errorhandler.NewUnauthorized("user not found")
	}

	_ = s.userRepo.DeleteRefreshToken(claims.ID)

	return s.issueTokenPair(user)
}

func (s *authService) Logout(jti string) error {
	return s.userRepo.DeleteRefreshToken(jti)
}

func (s *authService) LogoutAll(userID uint64) error {
	return s.userRepo.DeleteAllRefreshTokens(userID)
}

func (s *authService) issueTokenPair(user *models.User) (*TokenPair, error) {
	accessToken, err := helper.GenerateAccessToken(uint(user.ID), user.Role)
	if err != nil {
		return nil, errorhandler.NewInternalError("failed to generate access token")
	}

	refreshTokenStr, jti, err := helper.GenerateRefreshToken(uint(user.ID), user.Role)
	if err != nil {
		return nil, errorhandler.NewInternalError("failed to generate refresh token")
	}

	expiry := time.Now().Add(time.Duration(config.App.JWTRefreshExpDays) * 24 * time.Hour)
	if err := s.userRepo.CreateRefreshToken(&models.RefreshToken{
		UserID:    user.ID,
		TokenID:   jti,
		ExpiresAt: expiry,
	}); err != nil {
		return nil, errorhandler.NewInternalError("failed to store refresh token")
	}

	return &TokenPair{AccessToken: accessToken, RefreshToken: refreshTokenStr}, nil
}
