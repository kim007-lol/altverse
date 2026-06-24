package gamification

import (
	"strconv"

	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
)

type Controller struct {
	xpSvc          services.XPService
	missionSvc     services.MissionService
	badgeSvc       services.BadgeService
	leaderboardSvc services.LeaderboardService
}

func NewController(
	xpSvc services.XPService,
	missionSvc services.MissionService,
	badgeSvc services.BadgeService,
	leaderboardSvc services.LeaderboardService,
) *Controller {
	return &Controller{
		xpSvc:          xpSvc,
		missionSvc:     missionSvc,
		badgeSvc:       badgeSvc,
		leaderboardSvc: leaderboardSvc,
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
