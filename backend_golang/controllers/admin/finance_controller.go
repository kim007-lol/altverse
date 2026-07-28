package admin

import (
	"aureader/backend/controllers"
	"aureader/backend/helper"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type FinanceController struct{ db *gorm.DB }

func NewFinanceController(db *gorm.DB) *FinanceController { return &FinanceController{db: db} }

// GetOverview returns platform financial summary.
// Query param: period = 7d | 30d | 90d | all (default: 30d)
func (h *FinanceController) GetOverview(c *gin.Context) {
	period := c.DefaultQuery("period", "30d")
	interval := periodToInterval(period)

	type dailyRevenue struct {
		Day     string  `gorm:"column:day"     json:"day"`
		Revenue float64 `gorm:"column:revenue" json:"revenue"`
		Count   int     `gorm:"column:count"   json:"count"`
	}

	var dailyRevenues []dailyRevenue
	h.db.Raw(`
		SELECT TO_CHAR(created_at, 'YYYY-MM-DD') AS day,
		       SUM(amount_idr) AS revenue, COUNT(*) AS count
		FROM trx_transactions
		WHERE type = 'topup' AND status = 'success'
		  AND created_at >= NOW() - INTERVAL '`+interval+`'
		GROUP BY day ORDER BY day ASC
	`).Scan(&dailyRevenues)

	var totalRevenue float64
	var totalTopups int64
	h.db.Table("trx_transactions").
		Where("type = 'topup' AND status = 'success' AND created_at >= NOW() - INTERVAL ?", interval).
		Select("COALESCE(SUM(amount_idr),0)").Scan(&totalRevenue)
	h.db.Table("trx_transactions").
		Where("type = 'topup' AND status = 'success' AND created_at >= NOW() - INTERVAL ?", interval).
		Count(&totalTopups)

	var totalWithdrawn float64
	h.db.Table("trx_withdrawals").
		Where("status = 'success' AND created_at >= NOW() - INTERVAL ?", interval).
		Select("COALESCE(SUM(amount_idr),0)").Scan(&totalWithdrawn)

	var pendingWithdrawn float64
	h.db.Table("trx_withdrawals").Where("status = 'pending'").
		Select("COALESCE(SUM(amount_idr),0)").Scan(&pendingWithdrawn)

	helper.OK(c, "Finance overview fetched", gin.H{
		"period":           period,
		"total_revenue":    totalRevenue,
		"total_topups":     totalTopups,
		"total_withdrawn":  totalWithdrawn,
		"pending_withdraw": pendingWithdrawn,
		"net_retained":     totalRevenue - totalWithdrawn,
		"daily_revenue":    dailyRevenues,
	})
}

// GetAuthorEarnings returns top authors by coins received from tips/unlocks.
func (h *FinanceController) GetAuthorEarnings(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)

	type row struct {
		AuthorID    uint64  `gorm:"column:author_id"     json:"author_id"`
		Name        string  `gorm:"column:name"          json:"name"`
		PenName     *string `gorm:"column:pen_name"      json:"pen_name"`
		AvatarURL   *string `gorm:"column:avatar_url"    json:"avatar_url"`
		AuthorTier  string  `gorm:"column:author_tier"   json:"author_tier"`
		TotalEarned int     `gorm:"column:total_earned"  json:"total_earned"`
		TotalIDR    float64 `gorm:"column:total_idr"     json:"total_idr"`
	}

	var total int64
	h.db.Table("gam_season_author_earnings").
		Joins("JOIN usr_users u ON u.id = author_id AND u.deleted_at IS NULL").
		Select("COUNT(DISTINCT author_id)").Scan(&total)

	var rows []row
	h.db.Raw(`
		SELECT ae.author_id, u.name, u.pen_name, u.avatar_url, u.author_tier,
		       SUM(ae.coins_earned) AS total_earned,
		       SUM(ae.coins_earned) * 1500 AS total_idr
		FROM gam_season_author_earnings ae
		JOIN usr_users u ON u.id = ae.author_id AND u.deleted_at IS NULL
		GROUP BY ae.author_id, u.name, u.pen_name, u.avatar_url, u.author_tier
		ORDER BY total_earned DESC
		LIMIT ? OFFSET ?
	`, perPage, (page-1)*perPage).Scan(&rows)

	helper.Paginated(c, "Author earnings fetched", rows, page, perPage, total)
}

// GetTopSpenders returns readers ranked by total coins spent.
func (h *FinanceController) GetTopSpenders(c *gin.Context) {
	type row struct {
		UserID     uint64  `gorm:"column:user_id"     json:"user_id"`
		Name       string  `gorm:"column:name"        json:"name"`
		AvatarURL  *string `gorm:"column:avatar_url"  json:"avatar_url"`
		CoinsSpent int     `gorm:"column:coins_spent" json:"coins_spent"`
	}

	var rows []row
	h.db.Raw(`
		SELECT ss.user_id, u.name, u.avatar_url, SUM(ss.coins_spent) AS coins_spent
		FROM gam_season_supporters ss
		JOIN usr_users u ON u.id = ss.user_id AND u.deleted_at IS NULL
		GROUP BY ss.user_id, u.name, u.avatar_url
		ORDER BY coins_spent DESC LIMIT 20
	`).Scan(&rows)

	helper.OK(c, "Top spenders fetched", gin.H{"data": rows})
}

func periodToInterval(p string) string {
	switch p {
	case "7d":
		return "7 days"
	case "90d":
		return "90 days"
	case "all":
		return "36500 days" // ~100 years
	default:
		return "30 days"
	}
}
