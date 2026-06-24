package services

import (
	"aureader/backend/errorhandler"
	"aureader/backend/models"
	"aureader/backend/repositories"
)

type UpdateProfileInput struct {
	Name            *string
	PenName         *string
	Bio             *string
	ThemePreference *string
}

type UserService interface {
	GetProfile(userID uint64) (*models.User, error)
	UpdateProfile(userID uint64, input UpdateProfileInput) (*models.User, error)
	UpdateAvatar(userID uint64, avatarURL string) error
	GetCoins(userID uint64) (int, error)
	AddCoins(userID uint64, amount int) error
	DeductCoins(userID uint64, amount int) error
}

type userService struct {
	userRepo repositories.UserRepository
}

func NewUserService(userRepo repositories.UserRepository) UserService {
	return &userService{userRepo: userRepo}
}

func (s *userService) GetProfile(userID uint64) (*models.User, error) {
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return nil, errorhandler.NewNotFound("user not found")
	}
	return user, nil
}

func (s *userService) UpdateProfile(userID uint64, input UpdateProfileInput) (*models.User, error) {
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return nil, errorhandler.NewNotFound("user not found")
	}

	if input.Name != nil {
		user.Name = *input.Name
	}
	if input.PenName != nil {
		user.PenName = input.PenName
	}
	if input.Bio != nil {
		user.Bio = input.Bio
	}
	if input.ThemePreference != nil {
		user.ThemePreference = *input.ThemePreference
	}

	if err := s.userRepo.Update(user); err != nil {
		return nil, errorhandler.NewInternalError("failed to update profile")
	}
	return user, nil
}

func (s *userService) UpdateAvatar(userID uint64, avatarURL string) error {
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return errorhandler.NewNotFound("user not found")
	}
	user.AvatarURL = &avatarURL
	return s.userRepo.Update(user)
}

func (s *userService) GetCoins(userID uint64) (int, error) {
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return 0, errorhandler.NewNotFound("user not found")
	}
	return user.Coins, nil
}

func (s *userService) AddCoins(userID uint64, amount int) error {
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return errorhandler.NewNotFound("user not found")
	}
	user.Coins += amount
	return s.userRepo.Update(user)
}

func (s *userService) DeductCoins(userID uint64, amount int) error {
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return errorhandler.NewNotFound("user not found")
	}
	if user.Coins < amount {
		return errorhandler.NewInsufficientCoin()
	}
	user.Coins -= amount
	return s.userRepo.Update(user)
}
