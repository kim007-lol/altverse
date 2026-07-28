package routes

import (
	"aureader/backend/middleware"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// RegisterAdminRoutes wires all /api/v1/admin/* endpoints.
// The group is already protected by Auth + AdminOnly middleware from api.go.
func RegisterAdminRoutes(g *gin.RouterGroup, ctrl Controllers, db *gorm.DB) {
	// Every mutating admin request is recorded in adm_audit_logs.
	g.Use(middleware.AdminAudit(db))

	// Dashboard
	g.GET("/dashboard", ctrl.AdminDash.GetOverview)

	// User management
	g.GET("/users", ctrl.AdminUser.ListUsers)
	g.GET("/users/:id", ctrl.AdminUser.GetUserDetail)
	g.POST("/users/:id/status", ctrl.AdminUser.UpdateUserStatus)
	g.POST("/users/:id/coins", ctrl.AdminCoin.AdjustCoins)
	g.GET("/users/:id/coins/history", ctrl.AdminCoin.GetCoinHistory)

	// Content moderation
	g.GET("/content", ctrl.AdminContent.ListSeries)
	g.POST("/content/series/:id/takedown", ctrl.AdminContent.TakedownSeries)
	g.POST("/content/series/:id/restore", ctrl.AdminContent.RestoreSeries)

	// Report management
	g.GET("/reports", ctrl.AdminReport.ListReports)
	g.POST("/reports/:id/resolve", ctrl.AdminReport.ResolveReport)

	// Finance & withdrawals
	g.GET("/finance", ctrl.AdminFinance.GetOverview)
	g.GET("/finance/author-earnings", ctrl.AdminFinance.GetAuthorEarnings)
	g.GET("/finance/top-spenders", ctrl.AdminFinance.GetTopSpenders)
	g.GET("/withdrawals", ctrl.AdminWd.ListWithdrawals)
	g.POST("/withdrawals/:id/process", ctrl.AdminWd.Process)

	// Platform settings
	g.GET("/settings", ctrl.AdminSettings.GetSettings)
	g.PUT("/settings", ctrl.AdminSettings.UpdateSettings)

	// Broadcast notification
	g.POST("/broadcast", ctrl.AdminBroadcast.Send)

	// Audit logs
	g.GET("/audit-logs", ctrl.AdminAudit.ListAuditLogs)

	// Season management
	g.GET("/seasons", ctrl.AdminSeason.ListSeasons)
	g.POST("/seasons", ctrl.AdminSeason.CreateSeason)
	g.POST("/seasons/:id/end", ctrl.AdminSeason.EndSeason)
	g.GET("/seasons/:id/leaderboard", ctrl.AdminSeason.GetSeasonLeaderboard)
}
