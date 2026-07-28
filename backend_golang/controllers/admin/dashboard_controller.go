package admin

import (
	"aureader/backend/helper"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type DashboardController struct {
	db *gorm.DB
}

func NewDashboardController(db *gorm.DB) *DashboardController {
	return &DashboardController{db: db}
}

// GetOverview returns platform-wide health metrics for the admin dashboard.
func (h *DashboardController) GetOverview(c *gin.Context) {
	var totalUsers, totalAuthors, totalSeries, totalEpisodes int64
	var pendingWithdrawals, pendingReports int64
	var totalRevenueIDR float64

	h.db.Table("usr_users").Where("deleted_at IS NULL AND role != 'admin'").Count(&totalUsers)
	h.db.Table("usr_users").Where("deleted_at IS NULL AND role = 'author'").Count(&totalAuthors)
	h.db.Table("cnt_series").Where("deleted_at IS NULL").Count(&totalSeries)
	h.db.Table("cnt_episodes").Where("deleted_at IS NULL").Count(&totalEpisodes)
	h.db.Table("trx_transactions").
		Where("type = 'topup' AND status = 'success'").
		Select("COALESCE(SUM(amount_idr), 0)").Scan(&totalRevenueIDR)
	h.db.Table("trx_withdrawals").Where("status = 'pending'").Count(&pendingWithdrawals)
	h.db.Table("soc_reports").Where("status = 'pending'").Count(&pendingReports)

	// New user registrations per day for the last 7 days.
	type dayCount struct {
		Day   string `gorm:"column:day"   json:"day"`
		Count int64  `gorm:"column:count" json:"count"`
	}
	var userGrowth []dayCount
	h.db.Raw(`
		SELECT TO_CHAR(created_at, 'YYYY-MM-DD') AS day, COUNT(*) AS count
		FROM usr_users
		WHERE created_at >= NOW() - INTERVAL '7 days' AND deleted_at IS NULL
		GROUP BY day ORDER BY day ASC
	`).Scan(&userGrowth)

	// Top-up transactions in the last 7 days.
	type recentTopup struct {
		OrderID   string  `gorm:"column:order_id"   json:"order_id"`
		AmountIDR float64 `gorm:"column:amount_idr" json:"amount_idr"`
		Coins     int     `gorm:"column:coins"      json:"coins"`
		Status    string  `gorm:"column:status"     json:"status"`
		CreatedAt string  `gorm:"column:created_at" json:"created_at"`
	}
	var recentTopups []recentTopup
	h.db.Raw(`
		SELECT midtrans_order_id AS order_id, amount_idr, coins_requested AS coins, status,
		       TO_CHAR(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS created_at
		FROM trx_transactions
		WHERE type = 'topup'
		ORDER BY created_at DESC LIMIT 10
	`).Scan(&recentTopups)

	helper.OK(c, "Dashboard overview fetched", gin.H{
		"total_users":          totalUsers,
		"total_authors":        totalAuthors,
		"total_series":         totalSeries,
		"total_episodes":       totalEpisodes,
		"total_revenue_idr":    totalRevenueIDR,
		"pending_withdrawals":  pendingWithdrawals,
		"pending_reports":      pendingReports,
		"user_growth":          userGrowth,
		"recent_topups":        recentTopups,
	})
}
