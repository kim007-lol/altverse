package gamification

import (
	"strconv"

	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Controller struct {
	xpSvc          services.XPService
	missionSvc     services.MissionService
	badgeSvc       services.BadgeService
	leaderboardSvc services.LeaderboardService
	db             *gorm.DB
}

func NewController(
	xpSvc services.XPService,
	missionSvc services.MissionService,
	badgeSvc services.BadgeService,
	leaderboardSvc services.LeaderboardService,
	db *gorm.DB,
) *Controller {
	return &Controller{
		xpSvc:          xpSvc,
		missionSvc:     missionSvc,
		badgeSvc:       badgeSvc,
		leaderboardSvc: leaderboardSvc,
		db:             db,
	}
}

// ── XP ───────────────────────────────────────────────────────────────────────

func (h *Controller) GetMyXP(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	xp, err := h.xpSvc.GetUserXP(userID)
	if err != nil {
		helper.OK(c, "XP fetched", gin.H{"total_xp": 0, "current_level": 1})
		return
	}
	helper.OK(c, "XP fetched", xp)
}

// ── Missions ─────────────────────────────────────────────────────────────────

func (h *Controller) GetMissions(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	missions, err := h.missionSvc.GetUserMissions(userID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Missions fetched", missions)
}

func (h *Controller) ClaimMission(c *gin.Context) {
	var req dto.ClaimMissionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}
	userID := uint64(middleware.GetUserID(c))
	result, err := h.missionSvc.ClaimReward(userID, req.MissionID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Reward claimed", result)
}

// ClaimMissionByParam claims a mission whose id is in the URL path
// (POST /missions/:missionId/claim), matching the Flutter contract.
func (h *Controller) ClaimMissionByParam(c *gin.Context) {
	missionID, err := strconv.ParseUint(c.Param("missionId"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid mission id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))
	result, err := h.missionSvc.ClaimReward(userID, missionID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Reward claimed", result)
}

// ── Badges ───────────────────────────────────────────────────────────────────

func (h *Controller) GetAllBadges(c *gin.Context) {
	badges, err := h.badgeSvc.GetAllBadges()
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Badges fetched", badges)
}

func (h *Controller) GetMyBadges(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	badges, err := h.badgeSvc.GetUserBadges(userID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "My badges fetched", badges)
}

// ── Leaderboard ───────────────────────────────────────────────────────────────

func (h *Controller) GetCurrentLeaderboard(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)
	entries, total, err := h.leaderboardSvc.GetCurrentLeaderboard(page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Leaderboard fetched", entries, page, perPage, total)
}

func (h *Controller) GetSeasonLeaderboard(c *gin.Context) {
	seasonID, err := strconv.ParseUint(c.Param("season_id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid season id", nil)
		return
	}
	page, perPage := controllers.PaginationParams(c)
	entries, total, err := h.leaderboardSvc.GetLeaderboard(seasonID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Leaderboard fetched", entries, page, perPage, total)
}

func (h *Controller) GetActiveSeason(c *gin.Context) {
	season, err := h.leaderboardSvc.GetActiveSeason()
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Active season fetched", season)
}

// GetLeaderboardOverview returns the current user's leaderboard stats + active season.
// Includes my_xp, my_level, my_season_xp, my_season_spending, next_level_xp.
func (h *Controller) GetLeaderboardOverview(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	season, _ := h.leaderboardSvc.GetActiveSeason()

	userXP, _ := h.xpSvc.GetUserXP(userID)

	var mySeasonXp, mySeasonSpending int
	if season != nil {
		h.db.Table("gam_season_xp").
			Where("user_id = ? AND season_id = ?", userID, season.ID).
			Select("COALESCE(xp, 0)").Scan(&mySeasonXp)
		h.db.Table("gam_season_supporters").
			Where("user_id = ?", userID).
			Select("COALESCE(SUM(coins_spent), 0)").Scan(&mySeasonSpending)
	}

	// XP needed to reach next level: simple 100 * current_level formula.
	currentLevel := 1
	var totalXP int
	if userXP != nil {
		currentLevel = userXP.CurrentLevel
		totalXP = userXP.TotalXP
	}
	nextLevelXP := currentLevel * 100

	helper.OK(c, "Leaderboard overview fetched", gin.H{
		"season":   season,
		"my_level": currentLevel,
		"my_xp":    gin.H{"total_xp": totalXP},
		"my_season_xp": gin.H{"xp": mySeasonXp},
		"my_season_spending": gin.H{"total_spent": mySeasonSpending},
		"next_level_xp": nextLevelXP,
	})
}

// GetTopSupporters returns all-time top supporters (total coins spent per user).
// Response shape matches Flutter: [{user_id, total_spent, user: {name, avatar_url}}]
func (h *Controller) GetTopSupporters(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)
	offset := (page - 1) * perPage

	type rawRow struct {
		UserID     uint64  `gorm:"column:user_id"`
		Name       string  `gorm:"column:name"`
		AvatarURL  *string `gorm:"column:avatar_url"`
		CoinsSpent int     `gorm:"column:coins_spent"`
	}

	var rows []rawRow
	var total int64
	base := h.db.Table("gam_season_supporters ss").
		Select("ss.user_id, u.name, u.avatar_url, SUM(ss.coins_spent) AS coins_spent").
		Joins("JOIN usr_users u ON u.id = ss.user_id").
		Where("u.deleted_at IS NULL").
		Group("ss.user_id, u.name, u.avatar_url")

	base.Count(&total)
	base.Order("coins_spent DESC").Offset(offset).Limit(perPage).Scan(&rows)

	data := make([]gin.H, 0, len(rows))
	for _, r := range rows {
		data = append(data, gin.H{
			"user_id":     r.UserID,
			"total_spent": r.CoinsSpent,
			"user": gin.H{
				"id":         r.UserID,
				"name":       r.Name,
				"avatar_url": r.AvatarURL,
			},
		})
	}

	season, _ := h.leaderboardSvc.GetActiveSeason()
	helper.OK(c, "Top supporters fetched", gin.H{
		"data":   data,
		"season": season,
		"meta": gin.H{
			"total":     total,
			"page":      page,
			"per_page":  perPage,
			"last_page": max64(1, (int(total)+perPage-1)/perPage),
		},
	})
}

// GetTopAuthors returns authors ranked by total coins earned.
// Response shape matches Flutter: [{user_id, total_earned, user: {pen_name, avatar_url, author_tier}}]
func (h *Controller) GetTopAuthors(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)
	offset := (page - 1) * perPage

	type rawRow struct {
		AuthorID    uint64  `gorm:"column:author_id"`
		Name        string  `gorm:"column:name"`
		PenName     *string `gorm:"column:pen_name"`
		AvatarURL   *string `gorm:"column:avatar_url"`
		AuthorTier  string  `gorm:"column:author_tier"`
		CoinsEarned int     `gorm:"column:coins_earned"`
	}

	var rows []rawRow
	var total int64
	base := h.db.Table("gam_season_author_earnings ae").
		Select("ae.author_id, u.name, u.pen_name, u.avatar_url, u.author_tier, SUM(ae.coins_earned) AS coins_earned").
		Joins("JOIN usr_users u ON u.id = ae.author_id").
		Where("u.deleted_at IS NULL").
		Group("ae.author_id, u.name, u.pen_name, u.avatar_url, u.author_tier")

	base.Count(&total)
	base.Order("coins_earned DESC").Offset(offset).Limit(perPage).Scan(&rows)

	data := make([]gin.H, 0, len(rows))
	for _, r := range rows {
		data = append(data, gin.H{
			"user_id":      r.AuthorID,
			"total_earned": r.CoinsEarned,
			"user": gin.H{
				"id":                r.AuthorID,
				"name":              r.Name,
				"pen_name":          r.PenName,
				"avatar_url":        r.AvatarURL,
				"author_avatar_url": r.AvatarURL,
				"author_tier":       r.AuthorTier,
			},
		})
	}

	season, _ := h.leaderboardSvc.GetActiveSeason()
	helper.OK(c, "Top authors fetched", gin.H{
		"data":   data,
		"season": season,
		"meta": gin.H{
			"total":     total,
			"page":      page,
			"per_page":  perPage,
			"last_page": max64(1, (int(total)+perPage-1)/perPage),
		},
	})
}

// ClaimAllMissions claims every completed-but-unclaimed mission for the user in one call.
// Returns {total_xp, total_coins, claimed_count} so Flutter can update the UI atomically.
func (h *Controller) ClaimAllMissions(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	missions, err := h.missionSvc.GetUserMissions(userID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}

	var totalXP, totalCoins, claimedCount int
	for _, m := range missions {
		if !m.CanClaim {
			continue
		}
		result, claimErr := h.missionSvc.ClaimReward(userID, m.ID)
		if claimErr != nil {
			continue
		}
		totalXP += result.XPReward
		totalCoins += result.CoinReward
		claimedCount++
	}

	helper.OK(c, "All missions claimed", gin.H{
		"total_xp":      totalXP,
		"total_coins":   totalCoins,
		"claimed_count": claimedCount,
	})
}

// GetWalletBadges returns all badges with earned_at for each (null if not earned).
// Response: {badges: [...all with earned_at nullable...], earned: [...earned only...]}
func (h *Controller) GetWalletBadges(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))

	type row struct {
		ID            uint64  `gorm:"column:id"`
		Name          string  `gorm:"column:name"`
		Slug          string  `gorm:"column:slug"`
		Description   *string `gorm:"column:description"`
		IconURL       *string `gorm:"column:icon_url"`
		ConditionType string  `gorm:"column:condition_type"`
		ConditionValue int    `gorm:"column:condition_value"`
		EarnedAt      *string `gorm:"column:earned_at"`
	}
	var rows []row
	h.db.Raw(`
		SELECT b.id, b.name, b.slug, b.description, b.icon_url, b.condition_type, b.condition_value,
		       TO_CHAR(ub.earned_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS earned_at
		FROM gam_badges b
		LEFT JOIN gam_user_badges ub ON ub.badge_id = b.id AND ub.user_id = ?
		ORDER BY b.name ASC
	`, userID).Scan(&rows)

	allBadges := make([]gin.H, 0, len(rows))
	earned := make([]gin.H, 0)
	for _, r := range rows {
		item := gin.H{
			"id":              r.ID,
			"name":            r.Name,
			"slug":            r.Slug,
			"description":     r.Description,
			"icon_url":        r.IconURL,
			"condition_type":  r.ConditionType,
			"condition_value": r.ConditionValue,
			"earned_at":       r.EarnedAt,
		}
		allBadges = append(allBadges, item)
		if r.EarnedAt != nil {
			earned = append(earned, item)
		}
	}

	helper.OK(c, "Badges fetched", gin.H{"badges": allBadges, "earned": earned})
}

// PinBadge stubs the pin-badge action. The DB schema has no is_pinned column yet,
// so this returns 200 OK to prevent the Flutter screen from crashing.
func (h *Controller) PinBadge(c *gin.Context) {
	helper.OK(c, "Badge pin updated", nil)
}

// ── Tier Progress ────────────────────────────────────────────────────────────

// tierBenefits lists human-readable benefit keys per author tier.
var tierBenefits = map[string][]string{
	"bronze":  {},
	"silver":  {"banner_customization"},
	"gold":    {"banner_customization", "tipping"},
	"diamond": {"banner_customization", "tipping", "priority_search"},
	"popular": {"banner_customization", "tipping", "priority_search", "verified_badge"},
}

type tierReq struct {
	Followers      *int64 `json:"followers,omitempty"`
	Episodes       *int64 `json:"episodes,omitempty"`
	TotalViews     *int64 `json:"total_views,omitempty"`
	CompletedSeries *int64 `json:"completed_series,omitempty"`
}

// tierRequirements maps each tier to the minimum stats needed to reach it.
func tierRequirements() map[string]map[string]int64 {
	return map[string]map[string]int64{
		"silver":  {"followers": 100, "episodes": 5},
		"gold":    {"followers": 1000, "total_views": 50000},
		"diamond": {"followers": 5000, "total_views": 200000},
		"popular": {"followers": 10000, "completed_series": 1},
	}
}

// GetTierProgress returns the current user's author tier, benefits, and progress to next tier.
func (h *Controller) GetTierProgress(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))

	var user struct {
		AuthorTier string `gorm:"column:author_tier"`
	}
	h.db.Table("usr_users").Select("author_tier").Where("id = ?", userID).Scan(&user)

	currentTier := user.AuthorTier
	if currentTier == "" {
		currentTier = "bronze"
	}

	// Fetch live stats for progress computation.
	var followersCount int64
	h.db.Table("soc_follows").Where("following_id = ?", userID).Count(&followersCount)

	var episodesCount int64
	h.db.Raw(`
		SELECT COUNT(e.id) FROM cnt_episodes e
		JOIN cnt_series s ON s.id = e.series_id
		WHERE s.author_id = ? AND e.status = 'published'
	`, userID).Scan(&episodesCount)

	var totalViews int64
	h.db.Raw(`
		SELECT COALESCE(SUM(s.total_views), 0) FROM cnt_series s WHERE s.author_id = ?
	`, userID).Scan(&totalViews)

	var completedSeries int64
	h.db.Raw(`
		SELECT COUNT(*) FROM cnt_series s WHERE s.author_id = ? AND s.status = 'completed'
	`, userID).Scan(&completedSeries)

	stats := map[string]int64{
		"followers":        followersCount,
		"episodes":         episodesCount,
		"total_views":      totalViews,
		"completed_series": completedSeries,
	}

	tierOrder := []string{"bronze", "silver", "gold", "diamond", "popular"}
	reqs := tierRequirements()

	// Build progress map — only for tiers above current.
	progress := gin.H{}
	currentIdx := 0
	for i, t := range tierOrder {
		if t == currentTier {
			currentIdx = i
			break
		}
	}
	for _, tier := range tierOrder[currentIdx+1:] {
		req, ok := reqs[tier]
		if !ok {
			continue
		}
		requirements := gin.H{}
		for stat, required := range req {
			current := stats[stat]
			requirements[stat] = gin.H{
				"current":  current,
				"required": required,
				"met":      current >= required,
			}
		}
		progress[tier] = gin.H{"requirements": requirements}
		break // show only next tier's progress
	}

	helper.OK(c, "Tier progress fetched", gin.H{
		"current_tier":     currentTier,
		"current_benefits": tierBenefits[currentTier],
		"all_benefits":     tierBenefits,
		"progress":         progress,
	})
}

func max64(a, b int) int {
	if a > b {
		return a
	}
	return b
}
