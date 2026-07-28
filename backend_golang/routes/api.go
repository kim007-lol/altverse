package routes

import (
	adminCtrl "aureader/backend/controllers/admin"
	authorCtrl "aureader/backend/controllers/author"
	gamCtrl "aureader/backend/controllers/gamification"
	readerCtrl "aureader/backend/controllers/reader"
	sharedCtrl "aureader/backend/controllers/shared"
	"aureader/backend/middleware"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Controllers struct {
	Auth          *sharedCtrl.AuthController
	Profile       *readerCtrl.ProfileController
	Discover      *readerCtrl.DiscoverController
	Reading       *readerCtrl.ReadingController
	Social        *readerCtrl.SocialController
	Wallet        *readerCtrl.WalletController
	AuthSeries    *authorCtrl.SeriesController
	AuthEp        *authorCtrl.EpisodeController
	AdminWd        *adminCtrl.WithdrawalController
	AdminDash      *adminCtrl.DashboardController
	AdminUser      *adminCtrl.UserController
	AdminContent   *adminCtrl.ContentController
	AdminReport    *adminCtrl.ReportController
	AdminSettings  *adminCtrl.SettingsController
	AdminCoin      *adminCtrl.CoinController
	AdminBroadcast *adminCtrl.BroadcastController
	AdminAudit     *adminCtrl.AuditController
	AdminSeason    *adminCtrl.SeasonController
	AdminFinance   *adminCtrl.FinanceController
	Gam            *gamCtrl.Controller
	DB             *gorm.DB
	Image         *sharedCtrl.ImageProxyController
	Notif         *readerCtrl.NotificationController
	Unlock        *readerCtrl.UnlockController
}

func Register(r *gin.Engine, ctrl Controllers) {
	v1 := r.Group("/api/v1")

	// ── Public: Auth ─────────────────────────────────────────────────────────
	auth := v1.Group("/auth")
	{
		auth.POST("/register", ctrl.Auth.Register)
		auth.POST("/login", ctrl.Auth.Login)
		auth.POST("/refresh", ctrl.Auth.Refresh)
		auth.POST("/logout", middleware.Auth(), ctrl.Auth.Logout)
		auth.POST("/logout-all", middleware.Auth(), ctrl.Auth.LogoutAll)
		// Flutter contract aliases
		auth.GET("/me", middleware.Auth(), ctrl.Profile.Me)
		auth.PUT("/profile", middleware.Auth(), ctrl.Profile.UpdateProfile)
	}

	// ── Public: Discovery ────────────────────────────────────────────────────
	series := v1.Group("/series")
	{
		series.GET("", ctrl.Discover.ListSeries)
		series.GET("/:id", ctrl.Discover.GetSeries) // accepts numeric id or slug
		series.GET("/:id/episodes", ctrl.Discover.ListEpisodes)
	}
	v1.GET("/genres", ctrl.Discover.ListGenres)
	v1.GET("/public/genres", ctrl.Discover.ListGenres) // Flutter contract alias

	// ── Public: Comments & likes (read-only) ─────────────────────────────────
	v1.GET("/episodes/:id/comments", ctrl.Social.GetComments)

	// ── Webhook (no auth — Midtrans calls this) ───────────────────────────────
	v1.POST("/webhooks/midtrans", ctrl.Wallet.MidtransWebhook)

	// ── Authenticated: Reader ────────────────────────────────────────────────
	authed := v1.Group("", middleware.Auth())
	{
		// Profile
		authed.GET("/user/profile", ctrl.Profile.GetProfile)
		authed.PUT("/user/profile", ctrl.Profile.UpdateProfile)
		authed.GET("/user/wallet", ctrl.Profile.GetWallet)

		// Reading
		authed.GET("/episodes/:id/read", ctrl.Reading.ReadEpisode)
		authed.POST("/episodes/:id/progress", ctrl.Reading.UpdateProgress)
		authed.GET("/user/history", ctrl.Reading.GetHistory)

		// Social: follows
		authed.POST("/users/:id/follow", ctrl.Social.Follow)
		authed.DELETE("/users/:id/follow", ctrl.Social.Unfollow)
		authed.GET("/users/:id/followers", ctrl.Social.GetFollowers)
		authed.GET("/users/:id/following", ctrl.Social.GetFollowing)

		// Social: bookmarks
		authed.POST("/series/:id/bookmark", ctrl.Social.Bookmark)
		authed.DELETE("/series/:id/bookmark", ctrl.Social.Unbookmark)
		authed.GET("/user/bookmarks", ctrl.Social.GetBookmarks)

		// Social: likes
		authed.POST("/series/:id/like", ctrl.Social.ToggleSeriesLike)
		authed.POST("/episodes/:id/like", ctrl.Social.ToggleEpisodeLike)

		// Social: comments
		authed.POST("/episodes/:id/comments", ctrl.Social.CreateComment)
		authed.DELETE("/comments/:id", ctrl.Social.DeleteComment)

		// Wallet & top-up
		authed.GET("/user/transactions", ctrl.Wallet.GetTransactions)
		authed.POST("/topup", ctrl.Wallet.CreateTopUp)
		authed.GET("/topup/:order_id", ctrl.Wallet.TopUpStatus)
		authed.POST("/withdrawal", ctrl.Wallet.RequestWithdrawal)
		authed.GET("/user/withdrawals", ctrl.Wallet.GetWithdrawals)

		// ── Flutter contract aliases (Fase A) ────────────────────────────────
		// Reuse existing handlers under the paths the Flutter app expects.
		// Old paths above are kept so nothing breaks.

		// Wallet (consolidated balance + transactions)
		authed.GET("/wallet", ctrl.Wallet.GetWalletSummary)
		authed.GET("/reader/topup/history", ctrl.Wallet.GetTransactions)
		authed.POST("/reader/topup/create", ctrl.Wallet.CreateTopUp)
		authed.GET("/reader/topup/packages", ctrl.Wallet.GetTopupPackages)
		authed.POST("/wallet/tip", ctrl.Wallet.SendTip)
		authed.GET("/wallet/daily-status", ctrl.Wallet.GetDailyStatus)
		authed.POST("/wallet/daily-reward", ctrl.Wallet.ClaimDailyReward)

		// Auth extras
		authed.POST("/auth/switch-role", ctrl.Auth.SwitchRole)

		// Reader profile (self + public)
		authed.GET("/reader/profile", ctrl.Profile.Me)
		authed.GET("/reader/profile/:userId", ctrl.Discover.GetPublicReaderProfile)

		// Reader home FYP
		authed.GET("/reader/fyp", ctrl.Discover.GetFYP)

		// Reader author public profile
		authed.GET("/reader/author/:id/profile", ctrl.Discover.GetAuthorProfile)

		// Reader search + suggestions + history
		authed.GET("/reader/search", ctrl.Discover.Search)
		authed.GET("/reader/search/suggestions", ctrl.Discover.GetSearchSuggestions)
		authed.GET("/reader/search/history", ctrl.Discover.GetSearchHistory)
		authed.DELETE("/reader/search/history", ctrl.Discover.ClearSearchHistory)

		// Reader my comments
		authed.GET("/reader/my-comments", ctrl.Social.GetMyComments)

		// Comment like toggle
		authed.POST("/comments/:id/like", ctrl.Social.ToggleCommentLike)

		// Reader reading & content
		authed.GET("/reader/history", ctrl.Reading.GetHistory)
		authed.GET("/reader/series/:id", ctrl.Discover.GetSeries)
		authed.GET("/reader/series/:id/episodes", ctrl.Discover.ListEpisodes)
		authed.GET("/reader/series/:id/episodes/:episodeId", ctrl.Reading.ReadEpisodeNested)
		authed.POST("/reader/series/:id/like", ctrl.Social.ToggleSeriesLike)
		authed.POST("/reader/series/:id/episodes/:episodeId/like", ctrl.Social.ToggleEpisodeLikeNested)

		// Episode unlock / paywall
		authed.GET("/reader/episodes/unlocked", ctrl.Unlock.ListUnlocked)
		authed.POST("/reader/episodes/:id/unlock", ctrl.Unlock.Unlock)

		// Reader social — follow (self-scoped + toggle/check)
		authed.GET("/reader/following", ctrl.Social.GetMyFollowing)
		authed.GET("/reader/followers", ctrl.Social.GetMyFollowers)
		authed.POST("/reader/follow/:userId/toggle", ctrl.Social.ToggleFollow)
		authed.GET("/reader/follow/:userId/check", ctrl.Social.CheckFollow)

		// Reader social — bookmarks (toggle/check)
		authed.GET("/reader/bookmarks", ctrl.Social.GetBookmarks)
		authed.POST("/reader/bookmarks/:seriesId/toggle", ctrl.Social.ToggleBookmark)
		authed.GET("/reader/bookmarks/:seriesId/check", ctrl.Social.CheckBookmark)

		// Gamification aliases
		authed.GET("/missions", ctrl.Gam.GetMissions)
		authed.POST("/missions/:missionId/claim", ctrl.Gam.ClaimMissionByParam)
		authed.POST("/missions/claim-all", ctrl.Gam.ClaimAllMissions)
		authed.GET("/leaderboard/top-xp", ctrl.Gam.GetCurrentLeaderboard)
		authed.GET("/leaderboard/overview", ctrl.Gam.GetLeaderboardOverview)
		authed.GET("/leaderboard/top-supporters", ctrl.Gam.GetTopSupporters)
		authed.GET("/leaderboard/top-authors", ctrl.Gam.GetTopAuthors)

		// Badges (Flutter contract: /wallet/badges + /users/badges/:id/pin)
		authed.GET("/wallet/badges", ctrl.Gam.GetWalletBadges)
		authed.POST("/users/badges/:id/pin", ctrl.Gam.PinBadge)

		// Tier progress
		authed.GET("/wallet/tier-progress", ctrl.Gam.GetTierProgress)

		// Reports (user's own submissions)
		authed.GET("/reports", ctrl.Social.GetMyReports)
		authed.DELETE("/reports/:id", ctrl.Social.DeleteReport)

		// ── Notifications ────────────────────────────────────────────────────
		authed.GET("/notifications", ctrl.Notif.List)
		authed.GET("/notifications/unread-count", ctrl.Notif.UnreadCount)
		authed.POST("/notifications/read-all", ctrl.Notif.MarkAllRead)
		authed.POST("/notifications/cleanup", ctrl.Notif.Cleanup)
		authed.GET("/notifications/preferences", ctrl.Notif.GetPreferences)
		authed.PUT("/notifications/preferences", ctrl.Notif.UpdatePreferences)
		authed.POST("/notifications/:id/read", ctrl.Notif.MarkRead)
	}

	// ── Author ────────────────────────────────────────────────────────────────
	authorGroup := v1.Group("/author", middleware.Auth(), middleware.AuthorOnly())
	{
		authorGroup.GET("/series", ctrl.AuthSeries.ListMySeries)
		authorGroup.POST("/series", ctrl.AuthSeries.CreateSeries)
		authorGroup.PUT("/series/:id", ctrl.AuthSeries.UpdateSeries)
		authorGroup.POST("/series/:id/publish", ctrl.AuthSeries.PublishSeries)
		authorGroup.DELETE("/series/:id", ctrl.AuthSeries.DeleteSeries)

		// Withdrawals (Flutter calls these under /author, reuse wallet handlers)
		authorGroup.GET("/withdrawals", ctrl.Wallet.GetWithdrawals)
		authorGroup.POST("/withdrawals", ctrl.Wallet.RequestWithdrawal)

		authorGroup.GET("/series/:id/episodes", ctrl.AuthEp.ListEpisodes)
		authorGroup.POST("/series/:id/episodes", ctrl.AuthEp.CreateEpisode)
		authorGroup.PUT("/episodes/:id", ctrl.AuthEp.UpdateEpisode)
		authorGroup.POST("/episodes/:id/publish", ctrl.AuthEp.PublishEpisode)
		authorGroup.DELETE("/episodes/:id", ctrl.AuthEp.DeleteEpisode)
	}

	// ── Admin ─────────────────────────────────────────────────────────────────
	adminGroup := v1.Group("/admin", middleware.Auth(), middleware.AdminOnly())
	RegisterAdminRoutes(adminGroup, ctrl, ctrl.DB)

	// ── Gamification ─────────────────────────────────────────────────────────
	gam := v1.Group("/gamification", middleware.Auth())
	{
		gam.GET("/xp", ctrl.Gam.GetMyXP)
		gam.GET("/missions", ctrl.Gam.GetMissions)
		gam.POST("/missions/claim", ctrl.Gam.ClaimMission)
		gam.GET("/badges", ctrl.Gam.GetAllBadges)
		gam.GET("/badges/me", ctrl.Gam.GetMyBadges)
		gam.GET("/leaderboard", ctrl.Gam.GetCurrentLeaderboard)
		gam.GET("/leaderboard/:season_id", ctrl.Gam.GetSeasonLeaderboard)
		gam.GET("/season/active", ctrl.Gam.GetActiveSeason)
	}

	// ── Image Proxy (public, rate-limited) ───────────────────────────────────
	if ctrl.Image != nil {
		// Stats path must NOT share the /images/* catch-all prefix (Gin panics otherwise).
		r.GET("/image-cache/stats", ctrl.Image.CacheStats)
		r.GET("/images/*filepath", ctrl.Image.Serve)
	}
}
