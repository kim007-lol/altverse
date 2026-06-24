package models

import "time"

type ReadingHistory struct {
	UserID             uint64    `gorm:"primaryKey;not null"                    json:"user_id"`
	EpisodeID          uint64    `gorm:"primaryKey;not null;index"              json:"episode_id"`
	LastReadPage       int       `gorm:"not null;default:1"                     json:"last_read_page"`
	ProgressPercentage float64   `gorm:"type:numeric(5,2);not null;default:0"   json:"progress_percentage"`
	LastReadAt         time.Time `gorm:"not null;default:now()"                 json:"last_read_at"`
	CreatedAt          time.Time `gorm:"autoCreateTime"                         json:"created_at"`
	UpdatedAt          time.Time `gorm:"autoUpdateTime"                         json:"updated_at"`

	User    User    `gorm:"foreignKey:UserID"    json:"user,omitempty"`
	Episode Episode `gorm:"foreignKey:EpisodeID" json:"episode,omitempty"`
}

func (ReadingHistory) TableName() string { return "trc_reading_histories" }

type ViewLog struct {
	ID        uint64     `gorm:"primaryKey;autoIncrement"   json:"id"`
	EpisodeID uint64     `gorm:"not null;index"             json:"episode_id"`
	UserID    *uint64    `gorm:"index"                      json:"user_id"`
	IPAddress *string    `gorm:"type:varchar(45)"           json:"ip_address"`
	ViewedAt  time.Time  `gorm:"not null;default:now();index" json:"viewed_at"`

	Episode Episode `gorm:"foreignKey:EpisodeID" json:"-"`
	User    *User   `gorm:"foreignKey:UserID"    json:"user,omitempty"`
}

func (ViewLog) TableName() string { return "trc_views_log" }
