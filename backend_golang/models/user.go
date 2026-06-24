package models

import "time"

type User struct {
	ID              uint64     `gorm:"primaryKey;autoIncrement"             json:"id"`
	Name            string     `gorm:"type:varchar(255);not null"           json:"name"`
	Email           string     `gorm:"type:varchar(255);not null;uniqueIndex" json:"email"`
	Password        string     `gorm:"type:varchar(255);not null"           json:"-"`
	Role            string     `gorm:"type:usr_role;not null;default:reader" json:"role"`
	AvatarURL       *string    `gorm:"type:varchar(512)"                    json:"avatar_url"`
	PenName         *string    `gorm:"type:varchar(255)"                    json:"pen_name"`
	Bio             *string    `gorm:"type:text"                            json:"bio"`
	SocialLinks     *string    `gorm:"type:jsonb"                           json:"social_links"`
	Level           int        `gorm:"not null;default:1"                   json:"level"`
	ExpPoints       int        `gorm:"not null;default:0"                   json:"exp_points"`
	Coins           int        `gorm:"not null;default:0"                   json:"coins"`
	AuthorTier      string     `gorm:"type:varchar(50);not null;default:bronze" json:"author_tier"`
	ThemePreference string     `gorm:"type:varchar(20);not null;default:dark"   json:"theme_preference"`
	CreatedAt       time.Time  `gorm:"autoCreateTime"                       json:"created_at"`
	UpdatedAt       time.Time  `gorm:"autoUpdateTime"                       json:"updated_at"`
	DeletedAt       *time.Time `gorm:"index"                                json:"deleted_at,omitempty"`

	RefreshTokens []RefreshToken `gorm:"foreignKey:UserID" json:"-"`
}

func (User) TableName() string { return "usr_users" }

type RefreshToken struct {
	ID        uint64    `gorm:"primaryKey;autoIncrement"                json:"id"`
	UserID    uint64    `gorm:"not null;index"                          json:"user_id"`
	TokenID   string    `gorm:"type:varchar(255);not null;uniqueIndex"  json:"token_id"`
	ExpiresAt time.Time `gorm:"not null"                                json:"expires_at"`
	CreatedAt time.Time `gorm:"autoCreateTime"                          json:"created_at"`

	User User `gorm:"foreignKey:UserID" json:"-"`
}

func (RefreshToken) TableName() string { return "usr_refresh_tokens" }
