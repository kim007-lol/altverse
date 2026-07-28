package models

import (
	"time"

	"gorm.io/gorm"
)

type Genre struct {
	ID        uint64    `gorm:"primaryKey;autoIncrement"              json:"id"`
	Name      string    `gorm:"type:varchar(100);not null;uniqueIndex" json:"name"`
	Slug      string    `gorm:"type:varchar(100);not null;uniqueIndex" json:"slug"`
	CreatedAt time.Time `gorm:"autoCreateTime"                        json:"created_at"`

	Series []Series `gorm:"many2many:cnt_series_genres;" json:"-"`
}

func (Genre) TableName() string { return "cnt_genres" }

type Series struct {
	ID         uint64     `gorm:"primaryKey;autoIncrement"                     json:"id"`
	AuthorID   uint64     `gorm:"not null;index"                               json:"author_id"`
	Title      string     `gorm:"type:varchar(512);not null"                   json:"title"`
	Slug       string     `gorm:"type:varchar(512);not null;uniqueIndex"       json:"slug"`
	Synopsis   *string    `gorm:"type:text"                                    json:"synopsis"`
	CoverURL   *string    `gorm:"type:varchar(512)"                            json:"cover_url"`
	BannerURL  *string    `gorm:"type:varchar(512)"                            json:"banner_url"`
	Type       string     `gorm:"type:cnt_series_type;not null;default:manga"            json:"type"`
	Status     string     `gorm:"type:cnt_series_status;not null;default:draft;index"    json:"status"`
	TotalViews int64      `gorm:"not null;default:0;index:idx_series_views,sort:desc"    json:"total_views"`
	TotalLikes int64      `gorm:"not null;default:0"                                     json:"total_likes"`
	CreatedAt  time.Time  `gorm:"autoCreateTime"                               json:"created_at"`
	UpdatedAt  time.Time  `gorm:"autoUpdateTime"                               json:"updated_at"`
	DeletedAt  *time.Time `gorm:"index"                                        json:"deleted_at,omitempty"`

	Author   User      `gorm:"foreignKey:AuthorID"          json:"author,omitempty"`
	Genres   []Genre   `gorm:"many2many:cnt_series_genres;" json:"genres,omitempty"`
	Episodes []Episode `gorm:"foreignKey:SeriesID"          json:"-"`
}

func (Series) TableName() string { return "cnt_series" }

type Episode struct {
	ID            uint64     `gorm:"primaryKey;autoIncrement"                       json:"id"`
	SeriesID      uint64     `gorm:"not null;index"                                 json:"series_id"`
	Title         string     `gorm:"type:varchar(512);not null"                     json:"title"`
	EpisodeNumber float64    `gorm:"type:numeric(8,2);not null"                     json:"episode_number"`
	PriceCoins    int        `gorm:"not null;default:0"                             json:"coin_price"`
	Status        string     `gorm:"type:cnt_episode_status;not null;default:draft;index" json:"status"`
	PublishedAt   *time.Time `                                                       json:"published_at"`
	TotalViews    int64      `gorm:"not null;default:0"                             json:"total_views"`
	CreatedAt     time.Time  `gorm:"autoCreateTime"                                 json:"created_at"`
	UpdatedAt     time.Time  `gorm:"autoUpdateTime"                                 json:"updated_at"`
	DeletedAt     *time.Time `gorm:"index"                                          json:"deleted_at,omitempty"`

	// IsPremium is derived (not stored): true when the episode costs coins.
	// Populated automatically after every read via the AfterFind hook.
	IsPremium bool `gorm:"-" json:"is_premium"`

	Series Series `gorm:"foreignKey:SeriesID"  json:"-"`
	Pages  []Page `gorm:"foreignKey:EpisodeID" json:"pages,omitempty"`
}

func (Episode) TableName() string { return "cnt_episodes" }

// AfterFind derives transient fields the client expects but that aren't columns.
func (e *Episode) AfterFind(*gorm.DB) error {
	e.IsPremium = e.PriceCoins > 0
	return nil
}

type Page struct {
	ID         uint64    `gorm:"primaryKey;autoIncrement"   json:"id"`
	EpisodeID  uint64    `gorm:"not null;index"             json:"episode_id"`
	PageNumber int       `gorm:"not null"                   json:"page_number"`
	ImageURL   string    `gorm:"type:varchar(512);not null" json:"image_path"`
	CreatedAt  time.Time `gorm:"autoCreateTime"             json:"created_at"`

	Episode Episode `gorm:"foreignKey:EpisodeID" json:"-"`
}

func (Page) TableName() string { return "cnt_pages" }
