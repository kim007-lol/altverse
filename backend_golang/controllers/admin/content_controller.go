package admin

import (
	"time"

	"aureader/backend/controllers"
	"aureader/backend/helper"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type ContentController struct {
	db *gorm.DB
}

func NewContentController(db *gorm.DB) *ContentController {
	return &ContentController{db: db}
}

// ListSeries returns all series for admin review with author info.
// Query params: page, per_page, search, status (published|draft|taken_down)
func (h *ContentController) ListSeries(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)
	search := c.Query("search")
	status := c.Query("status")

	type seriesRow struct {
		ID          uint64     `gorm:"column:id"           json:"id"`
		Title       string     `gorm:"column:title"        json:"title"`
		AuthorID    uint64     `gorm:"column:author_id"    json:"author_id"`
		AuthorName  string     `gorm:"column:author_name"  json:"author_name"`
		Status      string     `gorm:"column:status"       json:"status"`
		TotalViews  int64      `gorm:"column:total_views"  json:"total_views"`
		TotalLikes  int        `gorm:"column:total_likes"  json:"total_likes"`
		EpCount     int64      `gorm:"column:ep_count"     json:"ep_count"`
		CreatedAt   time.Time  `gorm:"column:created_at"   json:"created_at"`
		DeletedAt   *time.Time `gorm:"column:deleted_at"   json:"deleted_at,omitempty"`
	}

	query := h.db.Table("cnt_series s").
		Select(`s.id, s.title, s.author_id, u.name AS author_name, s.status,
		        s.total_views, s.total_likes, COUNT(e.id) AS ep_count,
		        s.created_at, s.deleted_at`).
		Joins("LEFT JOIN usr_users u ON u.id = s.author_id").
		Joins("LEFT JOIN cnt_episodes e ON e.series_id = s.id AND e.deleted_at IS NULL").
		Group("s.id, u.name")

	if search != "" {
		query = query.Where("s.title ILIKE ? OR u.name ILIKE ?", "%"+search+"%", "%"+search+"%")
	}
	if status == "taken_down" {
		query = query.Where("s.deleted_at IS NOT NULL")
	} else if status != "" {
		query = query.Where("s.status = ? AND s.deleted_at IS NULL", status)
	}

	var total int64
	query.Count(&total)

	var rows []seriesRow
	query.Order("s.created_at DESC").
		Offset((page - 1) * perPage).Limit(perPage).
		Scan(&rows)

	helper.Paginated(c, "Content fetched", rows, page, perPage, total)
}

// TakedownSeries soft-deletes a series (hides from all readers).
func (h *ContentController) TakedownSeries(c *gin.Context) {
	seriesID := c.Param("id")
	now := time.Now()
	result := h.db.Exec("UPDATE cnt_series SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL", now, seriesID)
	if result.RowsAffected == 0 {
		helper.NotFound(c, "series not found or already taken down")
		return
	}
	helper.OK(c, "Series taken down", gin.H{"series_id": seriesID})
}

// RestoreSeries reverses a takedown.
func (h *ContentController) RestoreSeries(c *gin.Context) {
	seriesID := c.Param("id")
	h.db.Exec("UPDATE cnt_series SET deleted_at = NULL WHERE id = ?", seriesID)
	helper.OK(c, "Series restored", gin.H{"series_id": seriesID})
}
