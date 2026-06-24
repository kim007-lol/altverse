package models

import (
	"encoding/json"
	"time"
)

type Notification struct {
	ID        uint64          `gorm:"primaryKey;autoIncrement"      json:"id"`
	UserID    uint64          `gorm:"not null;index"                json:"user_id"`
	Type      string          `gorm:"type:varchar(100);not null"    json:"type"`
	Title     string          `gorm:"type:varchar(512);not null"    json:"title"`
	Body      string          `gorm:"type:text;not null"            json:"body"`
	Data      json.RawMessage `gorm:"type:jsonb"                    json:"data"`
	IsRead    bool            `gorm:"not null;default:false"        json:"is_read"`
	ReadAt    *time.Time      `                                     json:"read_at"`
	CreatedAt time.Time       `gorm:"autoCreateTime"                json:"created_at"`

	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

func (Notification) TableName() string { return "ntf_notifications" }

type NotificationPreference struct {
	ID               uint64    `gorm:"primaryKey;autoIncrement"      json:"id"`
	UserID           uint64    `gorm:"not null;uniqueIndex:uidx_np"  json:"user_id"`
	NotificationType string    `gorm:"type:varchar(100);not null;uniqueIndex:uidx_np" json:"notification_type"`
	// No GORM `default` tag on these bools: with one, GORM omits the zero
	// value (false) from INSERTs and the DB default wins, so an explicit
	// "false" never persists. DB-level defaults still come from the migration.
	Enabled          bool      `gorm:"not null"  json:"enabled"`
	PushEnabled      bool      `gorm:"not null"  json:"push_enabled"`
	EmailEnabled     bool      `gorm:"not null"  json:"email_enabled"`
	CreatedAt        time.Time `gorm:"autoCreateTime"                json:"created_at"`
	UpdatedAt        time.Time `gorm:"autoUpdateTime"                json:"updated_at"`

	User User `gorm:"foreignKey:UserID" json:"-"`
}

func (NotificationPreference) TableName() string { return "ntf_preferences" }
