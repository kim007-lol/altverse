package admin

import (
	"aureader/backend/controllers"
	"aureader/backend/helper"
	"aureader/backend/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type AuditController struct{ db *gorm.DB }

func NewAuditController(db *gorm.DB) *AuditController { return &AuditController{db: db} }

// ListAuditLogs returns paginated admin action history.
// Query params: page, per_page, admin_id, action
func (h *AuditController) ListAuditLogs(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)
	adminID := c.Query("admin_id")
	action := c.Query("action")

	query := h.db.Model(&models.AuditLog{})
	if adminID != "" {
		query = query.Where("admin_id = ?", adminID)
	}
	if action != "" {
		query = query.Where("action ILIKE ?", "%"+action+"%")
	}

	var total int64
	query.Count(&total)

	var logs []models.AuditLog
	query.Order("created_at DESC").
		Offset((page - 1) * perPage).Limit(perPage).
		Find(&logs)

	helper.Paginated(c, "Audit logs fetched", logs, page, perPage, total)
}
