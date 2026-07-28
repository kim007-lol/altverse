package admin

import (
	"time"

	"aureader/backend/controllers"
	"aureader/backend/helper"
	"aureader/backend/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type SeasonController struct{ db *gorm.DB }

func NewSeasonController(db *gorm.DB) *SeasonController { return &SeasonController{db: db} }

// ListSeasons returns all seasons, newest first.
func (h *SeasonController) ListSeasons(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)
	var total int64
	h.db.Model(&models.Season{}).Count(&total)

	var seasons []models.Season
	h.db.Order("start_date DESC").
		Offset((page - 1) * perPage).Limit(perPage).
		Find(&seasons)

	helper.Paginated(c, "Seasons fetched", seasons, page, perPage, total)
}

// CreateSeason starts a new season. Only one season may be active at a time.
// Body: {name, start_date (YYYY-MM-DD), end_date (YYYY-MM-DD)}
func (h *SeasonController) CreateSeason(c *gin.Context) {
	var req struct {
		Name      string `json:"name"       binding:"required"`
		StartDate string `json:"start_date" binding:"required"`
		EndDate   string `json:"end_date"   binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	start, err := time.Parse("2006-01-02", req.StartDate)
	if err != nil {
		helper.BadRequest(c, "invalid start_date format (YYYY-MM-DD)", nil)
		return
	}
	end, err2 := time.Parse("2006-01-02", req.EndDate)
	if err2 != nil || end.Before(start) {
		helper.BadRequest(c, "invalid end_date", nil)
		return
	}

	// Deactivate any currently active season.
	h.db.Model(&models.Season{}).Where("is_active = true").Update("is_active", false)

	season := models.Season{
		Name:      req.Name,
		StartDate: start,
		EndDate:   end,
		IsActive:  true,
	}
	if err := h.db.Create(&season).Error; err != nil {
		helper.InternalError(c, "Failed to create season")
		return
	}

	helper.Created(c, "Season created", season)
}

// EndSeason marks a season as inactive and records end timestamp.
func (h *SeasonController) EndSeason(c *gin.Context) {
	seasonID := c.Param("id")
	result := h.db.Model(&models.Season{}).
		Where("id = ? AND is_active = true", seasonID).
		Updates(map[string]any{
			"is_active": false,
			"end_date":  time.Now(),
		})

	if result.RowsAffected == 0 {
		helper.NotFound(c, "active season not found")
		return
	}
	helper.OK(c, "Season ended", gin.H{"season_id": seasonID})
}

// GetSeasonLeaderboard returns the top-XP leaderboard for a specific season.
func (h *SeasonController) GetSeasonLeaderboard(c *gin.Context) {
	seasonID := c.Param("id")

	type row struct {
		UserID    uint64  `gorm:"column:user_id"    json:"user_id"`
		Name      string  `gorm:"column:name"       json:"name"`
		AvatarURL *string `gorm:"column:avatar_url" json:"avatar_url"`
		XP        int     `gorm:"column:xp"         json:"xp"`
		Rank      int     `gorm:"column:rank"       json:"rank"`
	}

	var rows []row
	h.db.Raw(`
		SELECT sx.user_id, u.name, u.avatar_url, sx.xp,
		       RANK() OVER (ORDER BY sx.xp DESC) AS rank
		FROM gam_season_xp sx
		JOIN usr_users u ON u.id = sx.user_id
		WHERE sx.season_id = ? AND u.deleted_at IS NULL
		ORDER BY sx.xp DESC LIMIT 50
	`, seasonID).Scan(&rows)

	helper.OK(c, "Season leaderboard fetched", gin.H{"data": rows})
}
