package repositories

import (
	"aureader/backend/models"

	"gorm.io/gorm"
)

type UserRepository interface {
	FindByID(id uint64) (*models.User, error)
	FindByEmail(email string) (*models.User, error)
	Create(user *models.User) error
	Update(user *models.User) error
	// AddCoins atomically increments a user's coin balance, avoiding the
	// lost-update race of a read-modify-write Save.
	AddCoins(userID uint64, delta int) error
	SoftDelete(id uint64) error
	CreateRefreshToken(token *models.RefreshToken) error
	FindRefreshToken(jti string) (*models.RefreshToken, error)
	DeleteRefreshToken(jti string) error
	DeleteAllRefreshTokens(userID uint64) error
	// FindPopularAuthors returns the top n authors ranked by total follower count.
	FindPopularAuthors(limit int) ([]models.User, error)
}

type userRepository struct{ db *gorm.DB }

func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) FindByID(id uint64) (*models.User, error) {
	var user models.User
	err := r.db.First(&user, id).Error
	return &user, err
}

func (r *userRepository) FindByEmail(email string) (*models.User, error) {
	var user models.User
	err := r.db.Where("email = ? AND deleted_at IS NULL", email).First(&user).Error
	return &user, err
}

func (r *userRepository) Create(user *models.User) error {
	return r.db.Create(user).Error
}

func (r *userRepository) Update(user *models.User) error {
	return r.db.Save(user).Error
}

func (r *userRepository) AddCoins(userID uint64, delta int) error {
	return r.db.Model(&models.User{}).Where("id = ?", userID).
		UpdateColumn("coins", gorm.Expr("coins + ?", delta)).Error
}

func (r *userRepository) SoftDelete(id uint64) error {
	return r.db.Model(&models.User{}).Where("id = ?", id).
		Update("deleted_at", gorm.Expr("NOW()")).Error
}

func (r *userRepository) CreateRefreshToken(token *models.RefreshToken) error {
	return r.db.Create(token).Error
}

func (r *userRepository) FindRefreshToken(jti string) (*models.RefreshToken, error) {
	var token models.RefreshToken
	err := r.db.Where("token_id = ?", jti).First(&token).Error
	return &token, err
}

func (r *userRepository) DeleteRefreshToken(jti string) error {
	return r.db.Where("token_id = ?", jti).Delete(&models.RefreshToken{}).Error
}

func (r *userRepository) DeleteAllRefreshTokens(userID uint64) error {
	return r.db.Where("user_id = ?", userID).Delete(&models.RefreshToken{}).Error
}

func (r *userRepository) FindPopularAuthors(limit int) ([]models.User, error) {
	var users []models.User
	// Subquery: count followers per author, then join to filter only author-role users.
	err := r.db.
		Joins("JOIN (SELECT followed_id, COUNT(*) AS follower_count FROM soc_follows GROUP BY followed_id) fc ON fc.followed_id = users.id").
		Where("users.role = 'author' AND users.deleted_at IS NULL").
		Order("fc.follower_count DESC").
		Limit(limit).
		Find(&users).Error
	return users, err
}
