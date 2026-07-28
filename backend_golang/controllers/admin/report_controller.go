package admin

import (
	"time"

	"aureader/backend/controllers"
	"aureader/backend/helper"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type ReportController struct {
	db *gorm.DB
}

func NewReportController(db *gorm.DB) *ReportController {
	return &ReportController{db: db}
}

// ListReports returns all community reports with reporter info.
// Query params: page, per_page, status (pending|resolved|dismissed)
func (h *ReportController) ListReports(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)
	status := c.Query("status")

	type reportRow struct {
		ID           uint64    `gorm:"column:id"            json:"id"`
		ReporterID   uint64    `gorm:"column:reporter_id"   json:"reporter_id"`
		ReporterName string    `gorm:"column:reporter_name" json:"reporter_name"`
		TargetType   string    `gorm:"column:target_type"   json:"target_type"`
		TargetID     uint64    `gorm:"column:target_id"     json:"target_id"`
		Reason       string    `gorm:"column:reason"        json:"reason"`
		Status       string    `gorm:"column:status"        json:"status"`
		CreatedAt    time.Time `gorm:"column:created_at"    json:"created_at"`
	}

	query := h.db.Table("soc_reports r").
		Select("r.id, r.reporter_id, u.name AS reporter_name, r.target_type, r.target_id, r.reason, r.status, r.created_at").
		Joins("LEFT JOIN usr_users u ON u.id = r.reporter_id")

	if status != "" {
		query = query.Where("r.status = ?", status)
	}

	var total int64
	countQ := h.db.Table("soc_reports")
	if status != "" {
		countQ = countQ.Where("status = ?", status)
	}
	countQ.Count(&total)

	var rows []reportRow
	query.Order("r.created_at DESC").
		Offset((page - 1) * perPage).Limit(perPage).
		Scan(&rows)

	helper.Paginated(c, "Reports fetched", rows, page, perPage, total)
}

// ResolveReport updates a report's status to resolved or dismissed.
// Body: {"status": "resolved" | "dismissed"}
func (h *ReportController) ResolveReport(c *gin.Context) {
	reportID := c.Param("id")

	var body struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}
	if body.Status != "resolved" && body.Status != "dismissed" {
		helper.BadRequest(c, "status must be resolved or dismissed", nil)
		return
	}

	result := h.db.Exec("UPDATE soc_reports SET status = ?, updated_at = ? WHERE id = ?",
		body.Status, time.Now(), reportID)
	if result.RowsAffected == 0 {
		helper.NotFound(c, "report not found")
		return
	}

	helper.OK(c, "Report updated", gin.H{"report_id": reportID, "status": body.Status})
}
