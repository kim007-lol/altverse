package admin

import (
	"time"

	"aureader/backend/controllers"
	"aureader/backend/helper"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type UserController struct {
	db *gorm.DB
}

func NewUserController(db *gorm.DB) *UserController {
	return &UserController{db: db}
}

// ListUsers returns a paginated, searchable list of all users.
// Query params: page, per_page, search (name/email), role (reader|author|admin)
func (h *UserController) ListUsers(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)
	search := c.Query("search")
	role := c.Query("role")

	type userRow struct {
		ID        uint64     `gorm:"column:id"         json:"id"`
		Name      string     `gorm:"column:name"       json:"name"`
		Email     string     `gorm:"column:email"      json:"email"`
		Role      string     `gorm:"column:role"       json:"role"`
		AvatarURL *string    `gorm:"column:avatar_url" json:"avatar_url"`
		Coins     int        `gorm:"column:coins"      json:"coins"`
		Level     int        `gorm:"column:level"      json:"level"`
		Status    string     `gorm:"column:status"     json:"status"`
		CreatedAt time.Time  `gorm:"column:created_at" json:"created_at"`
		DeletedAt *time.Time `gorm:"column:deleted_at" json:"deleted_at,omitempty"`
	}

	query := h.db.Table("usr_users").
		Select("id, name, email, role, avatar_url, coins, level, deleted_at, created_at, CASE WHEN deleted_at IS NOT NULL THEN 'banned' ELSE 'active' END AS status")

	if search != "" {
		query = query.Where("name ILIKE ? OR email ILIKE ?", "%"+search+"%", "%"+search+"%")
	}
	if role != "" {
		query = query.Where("role = ?", role)
	}

	var total int64
	query.Count(&total)

	var rows []userRow
	query.Order("created_at DESC").
		Offset((page - 1) * perPage).Limit(perPage).
		Scan(&rows)

	helper.Paginated(c, "Users fetched", rows, page, perPage, total)
}

// UpdateUserStatus suspends or restores a user by toggling deleted_at.
// Body: {"status": "active" | "banned"}
func (h *UserController) UpdateUserStatus(c *gin.Context) {
	userID := c.Param("id")

	var body struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	switch body.Status {
	case "active":
		h.db.Exec("UPDATE usr_users SET deleted_at = NULL WHERE id = ?", userID)
	case "banned", "suspended":
		now := time.Now()
		h.db.Exec("UPDATE usr_users SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL", now, userID)
	default:
		helper.BadRequest(c, "status must be active, banned, or suspended", nil)
		return
	}

	helper.OK(c, "User status updated", gin.H{"user_id": userID, "status": body.Status})
}

// GetUserDetail returns full profile data for a single user.
func (h *UserController) GetUserDetail(c *gin.Context) {
	userID := c.Param("id")

	type userDetail struct {
		ID          uint64     `gorm:"column:id"           json:"id"`
		Name        string     `gorm:"column:name"         json:"name"`
		Email       string     `gorm:"column:email"        json:"email"`
		Role        string     `gorm:"column:role"         json:"role"`
		AvatarURL   *string    `gorm:"column:avatar_url"   json:"avatar_url"`
		PenName     *string    `gorm:"column:pen_name"     json:"pen_name"`
		Coins       int        `gorm:"column:coins"        json:"coins"`
		Level       int        `gorm:"column:level"        json:"level"`
		ExpPoints   int        `gorm:"column:exp_points"   json:"exp_points"`
		AuthorTier  string     `gorm:"column:author_tier"  json:"author_tier"`
		Status      string     `gorm:"column:status"       json:"status"`
		CreatedAt   time.Time  `gorm:"column:created_at"   json:"created_at"`
		DeletedAt   *time.Time `gorm:"column:deleted_at"   json:"deleted_at,omitempty"`
		SeriesCount int64      `gorm:"column:series_count" json:"series_count"`
	}

	var row userDetail
	h.db.Raw(`
		SELECT u.*, CASE WHEN u.deleted_at IS NOT NULL THEN 'banned' ELSE 'active' END AS status,
		       COUNT(s.id) AS series_count
		FROM usr_users u
		LEFT JOIN cnt_series s ON s.author_id = u.id AND s.deleted_at IS NULL
		WHERE u.id = ?
		GROUP BY u.id
	`, userID).Scan(&row)

	if row.ID == 0 {
		helper.NotFound(c, "user not found")
		return
	}

	helper.OK(c, "User detail fetched", row)
}
