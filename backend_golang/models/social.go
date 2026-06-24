package models

import "time"

type Follow struct {
	FollowerID uint64    `gorm:"primaryKey;not null;index" json:"follower_id"`
	FollowedID uint64    `gorm:"primaryKey;not null;index" json:"followed_id"`
	CreatedAt  time.Time `gorm:"autoCreateTime"            json:"created_at"`

	Follower User `gorm:"foreignKey:FollowerID" json:"follower,omitempty"`
	Followed User `gorm:"foreignKey:FollowedID" json:"followed,omitempty"`
}

func (Follow) TableName() string { return "soc_follows" }

type Bookmark struct {
	UserID    uint64    `gorm:"primaryKey;not null;index" json:"user_id"`
	SeriesID  uint64    `gorm:"primaryKey;not null;index" json:"series_id"`
	CreatedAt time.Time `gorm:"autoCreateTime"            json:"created_at"`

	User   User   `gorm:"foreignKey:UserID"   json:"user,omitempty"`
	Series Series `gorm:"foreignKey:SeriesID" json:"series,omitempty"`
}

func (Bookmark) TableName() string { return "soc_bookmarks" }

type SeriesLike struct {
	UserID    uint64    `gorm:"primaryKey;not null;index" json:"user_id"`
	SeriesID  uint64    `gorm:"primaryKey;not null;index" json:"series_id"`
	CreatedAt time.Time `gorm:"autoCreateTime"            json:"created_at"`

	User   User   `gorm:"foreignKey:UserID"   json:"user,omitempty"`
	Series Series `gorm:"foreignKey:SeriesID" json:"series,omitempty"`
}

func (SeriesLike) TableName() string { return "soc_series_likes" }

type EpisodeLike struct {
	UserID    uint64    `gorm:"primaryKey;not null;index" json:"user_id"`
	EpisodeID uint64    `gorm:"primaryKey;not null;index" json:"episode_id"`
	CreatedAt time.Time `gorm:"autoCreateTime"            json:"created_at"`

	User    User    `gorm:"foreignKey:UserID"    json:"user,omitempty"`
	Episode Episode `gorm:"foreignKey:EpisodeID" json:"episode,omitempty"`
}

func (EpisodeLike) TableName() string { return "soc_episode_likes" }

type Comment struct {
	ID        uint64     `gorm:"primaryKey;autoIncrement"  json:"id"`
	UserID    uint64     `gorm:"not null;index"            json:"user_id"`
	EpisodeID uint64     `gorm:"not null;index"            json:"episode_id"`
	ParentID  *uint64    `gorm:"index"                     json:"parent_id"`
	Content   string     `gorm:"type:text;not null"        json:"content"`
	IsPinned  bool       `gorm:"not null;default:false"    json:"is_pinned"`
	CreatedAt time.Time  `gorm:"autoCreateTime"            json:"created_at"`
	UpdatedAt time.Time  `gorm:"autoUpdateTime"            json:"updated_at"`
	DeletedAt *time.Time `gorm:"index"                     json:"deleted_at,omitempty"`

	User    User      `gorm:"foreignKey:UserID"    json:"user,omitempty"`
	Episode Episode   `gorm:"foreignKey:EpisodeID" json:"-"`
	Parent  *Comment  `gorm:"foreignKey:ParentID"  json:"parent,omitempty"`
	Replies []Comment `gorm:"foreignKey:ParentID"  json:"replies,omitempty"`
	Likes   []CommentLike `gorm:"foreignKey:CommentID" json:"-"`
}

func (Comment) TableName() string { return "soc_comments" }

type CommentLike struct {
	UserID    uint64    `gorm:"primaryKey;not null;index" json:"user_id"`
	CommentID uint64    `gorm:"primaryKey;not null;index" json:"comment_id"`
	CreatedAt time.Time `gorm:"autoCreateTime"            json:"created_at"`

	User    User    `gorm:"foreignKey:UserID"    json:"user,omitempty"`
	Comment Comment `gorm:"foreignKey:CommentID" json:"-"`
}

func (CommentLike) TableName() string { return "soc_comment_likes" }

type Report struct {
	ID         uint64    `gorm:"primaryKey;autoIncrement"           json:"id"`
	ReporterID uint64    `gorm:"not null;index"                     json:"reporter_id"`
	TargetType string    `gorm:"type:soc_report_target;not null"    json:"target_type"`
	TargetID   uint64    `gorm:"not null"                           json:"target_id"`
	Reason     string    `gorm:"type:varchar(512);not null"         json:"reason"`
	Status     string    `gorm:"type:soc_report_status;not null;default:pending" json:"status"`
	CreatedAt  time.Time `gorm:"autoCreateTime"                     json:"created_at"`
	UpdatedAt  time.Time `gorm:"autoUpdateTime"                     json:"updated_at"`

	Reporter User `gorm:"foreignKey:ReporterID" json:"reporter,omitempty"`
}

func (Report) TableName() string { return "soc_reports" }
