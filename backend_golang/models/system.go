package models

import (
	"encoding/json"
	"time"
)

type Setting struct {
	ID          uint64          `gorm:"primaryKey;autoIncrement"           json:"id"`
	Key         string          `gorm:"type:varchar(255);not null;uniqueIndex" json:"key"`
	Value       json.RawMessage `gorm:"type:jsonb"                         json:"value"`
	Description *string         `gorm:"type:text"                          json:"description"`
	CreatedAt   time.Time       `gorm:"autoCreateTime"                     json:"created_at"`
	UpdatedAt   time.Time       `gorm:"autoUpdateTime"                     json:"updated_at"`
}

func (Setting) TableName() string { return "sys_settings" }
