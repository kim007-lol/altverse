package models

import "time"

type UserXP struct {
	UserID       uint64    `gorm:"primaryKey;not null"  json:"user_id"`
	TotalXP      int       `gorm:"not null;default:0"   json:"total_xp"`
	CurrentLevel int       `gorm:"not null;default:1"   json:"current_level"`
	CreatedAt    time.Time `gorm:"autoCreateTime"       json:"created_at"`
	UpdatedAt    time.Time `gorm:"autoUpdateTime"       json:"updated_at"`

	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

func (UserXP) TableName() string { return "gam_user_xp" }

type DailyXPLog struct {
	ID        uint64    `gorm:"primaryKey;autoIncrement"      json:"id"`
	UserID    uint64    `gorm:"not null;index:idx_user_date"  json:"user_id"`
	Source    string    `gorm:"type:varchar(100);not null"    json:"source"`
	XPEarned  int       `gorm:"not null;default:0"            json:"xp_earned"`
	LogDate   time.Time `gorm:"type:date;not null;index:idx_user_date" json:"log_date"`
	CreatedAt time.Time `gorm:"autoCreateTime"                json:"created_at"`

	User User `gorm:"foreignKey:UserID" json:"-"`
}

func (DailyXPLog) TableName() string { return "gam_daily_xp_logs" }

type Badge struct {
	ID             uint64    `gorm:"primaryKey;autoIncrement"          json:"id"`
	Name           string    `gorm:"type:varchar(255);not null;uniqueIndex" json:"name"`
	Slug           string    `gorm:"type:varchar(255);not null;uniqueIndex" json:"slug"`
	Description    *string   `gorm:"type:text"                         json:"description"`
	IconURL        *string   `gorm:"type:varchar(512)"                 json:"icon_url"`
	ConditionType  string    `gorm:"type:varchar(100);not null"        json:"condition_type"`
	ConditionValue int       `gorm:"not null;default:0"                json:"condition_value"`
	CreatedAt      time.Time `gorm:"autoCreateTime"                    json:"created_at"`
}

func (Badge) TableName() string { return "gam_badges" }

type UserBadge struct {
	UserID   uint64    `gorm:"primaryKey;not null" json:"user_id"`
	BadgeID  uint64    `gorm:"primaryKey;not null" json:"badge_id"`
	EarnedAt time.Time `gorm:"autoCreateTime"      json:"earned_at"`

	User  User  `gorm:"foreignKey:UserID"  json:"user,omitempty"`
	Badge Badge `gorm:"foreignKey:BadgeID" json:"badge,omitempty"`
}

func (UserBadge) TableName() string { return "gam_user_badges" }

type Mission struct {
	ID             uint64    `gorm:"primaryKey;autoIncrement"           json:"id"`
	Title          string    `gorm:"type:varchar(512);not null"         json:"title"`
	Description    *string   `gorm:"type:text"                          json:"description"`
	Type           string    `gorm:"type:gam_mission_type;not null"     json:"type"`
	XPReward       int       `gorm:"not null;default:0"                 json:"xp_reward"`
	CoinReward     int       `gorm:"not null;default:0"                 json:"coin_reward"`
	ConditionType  string    `gorm:"type:varchar(100);not null"         json:"condition_type"`
	ConditionValue int       `gorm:"not null;default:1"                 json:"condition_value"`
	IsActive       bool      `gorm:"not null;default:true"              json:"is_active"`
	CreatedAt      time.Time `gorm:"autoCreateTime"                     json:"created_at"`
	UpdatedAt      time.Time `gorm:"autoUpdateTime"                     json:"updated_at"`
}

func (Mission) TableName() string { return "gam_missions" }

type UserMission struct {
	ID          uint64     `gorm:"primaryKey;autoIncrement"           json:"id"`
	UserID      uint64     `gorm:"not null;uniqueIndex:uidx_um"       json:"user_id"`
	MissionID   uint64     `gorm:"not null;uniqueIndex:uidx_um"       json:"mission_id"`
	Status      string     `gorm:"type:gam_mission_status;not null;default:in_progress" json:"status"`
	Progress    int        `gorm:"not null;default:0"                 json:"progress"`
	CompletedAt *time.Time `                                          json:"completed_at"`
	ClaimedAt   *time.Time `                                          json:"claimed_at"`
	CreatedAt   time.Time  `gorm:"autoCreateTime"                     json:"created_at"`
	UpdatedAt   time.Time  `gorm:"autoUpdateTime"                     json:"updated_at"`

	User    User    `gorm:"foreignKey:UserID"    json:"user,omitempty"`
	Mission Mission `gorm:"foreignKey:MissionID" json:"mission,omitempty"`
}

func (UserMission) TableName() string { return "gam_user_missions" }

type Season struct {
	ID        uint64    `gorm:"primaryKey;autoIncrement"      json:"id"`
	Name      string    `gorm:"type:varchar(255);not null"    json:"name"`
	StartDate time.Time `gorm:"type:date;not null"            json:"start_date"`
	EndDate   time.Time `gorm:"type:date;not null"            json:"end_date"`
	IsActive  bool      `gorm:"not null;default:false"        json:"is_active"`
	CreatedAt time.Time `gorm:"autoCreateTime"                json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime"                json:"updated_at"`
}

func (Season) TableName() string { return "gam_seasons" }

type SeasonXP struct {
	UserID    uint64    `gorm:"primaryKey;not null" json:"user_id"`
	SeasonID  uint64    `gorm:"primaryKey;not null" json:"season_id"`
	XP        int       `gorm:"not null;default:0"  json:"xp"`
	Rank      *int      `                           json:"rank"`
	CreatedAt time.Time `gorm:"autoCreateTime"      json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime"      json:"updated_at"`

	User   User   `gorm:"foreignKey:UserID"   json:"user,omitempty"`
	Season Season `gorm:"foreignKey:SeasonID" json:"season,omitempty"`
}

func (SeasonXP) TableName() string { return "gam_season_xp" }

type SeasonSupporter struct {
	UserID     uint64    `gorm:"primaryKey;not null" json:"user_id"`
	AuthorID   uint64    `gorm:"primaryKey;not null" json:"author_id"`
	SeasonID   uint64    `gorm:"primaryKey;not null" json:"season_id"`
	CoinsSpent int       `gorm:"not null;default:0"  json:"coins_spent"`
	CreatedAt  time.Time `gorm:"autoCreateTime"      json:"created_at"`
	UpdatedAt  time.Time `gorm:"autoUpdateTime"      json:"updated_at"`

	User   User   `gorm:"foreignKey:UserID"   json:"user,omitempty"`
	Author User   `gorm:"foreignKey:AuthorID" json:"author,omitempty"`
	Season Season `gorm:"foreignKey:SeasonID" json:"season,omitempty"`
}

func (SeasonSupporter) TableName() string { return "gam_season_supporters" }

type SeasonAuthorEarning struct {
	AuthorID     uint64  `gorm:"primaryKey;not null"    json:"author_id"`
	SeasonID     uint64  `gorm:"primaryKey;not null"    json:"season_id"`
	CoinsEarned  int     `gorm:"not null;default:0"     json:"coins_earned"`
	RupiahEarned float64 `gorm:"type:numeric(15,2);not null;default:0" json:"rupiah_earned"`
	CreatedAt    time.Time `gorm:"autoCreateTime"       json:"created_at"`
	UpdatedAt    time.Time `gorm:"autoUpdateTime"       json:"updated_at"`

	Author User   `gorm:"foreignKey:AuthorID" json:"author,omitempty"`
	Season Season `gorm:"foreignKey:SeasonID" json:"season,omitempty"`
}

func (SeasonAuthorEarning) TableName() string { return "gam_season_author_earnings" }
