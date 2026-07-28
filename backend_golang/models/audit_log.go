package models

import "time"

type AuditLog struct {
	ID         uint64    `gorm:"primaryKey;autoIncrement"         json:"id"`
	AdminID    uint64    `gorm:"not null;index"                   json:"admin_id"`
	AdminName  string    `gorm:"type:varchar(255);not null"       json:"admin_name"`
	Action     string    `gorm:"type:varchar(100);not null;index" json:"action"`
	TargetType string    `gorm:"type:varchar(100)"               json:"target_type"`
	TargetID   string    `gorm:"type:varchar(100)"               json:"target_id"`
	Detail     string    `gorm:"type:text"                        json:"detail"`
	IPAddress  string    `gorm:"type:varchar(45)"                 json:"ip_address"`
	StatusCode int       `gorm:"not null;default:200"             json:"status_code"`
	CreatedAt  time.Time `gorm:"autoCreateTime;index"             json:"created_at"`
}

func (AuditLog) TableName() string { return "adm_audit_logs" }
