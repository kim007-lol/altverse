package reader

import (
	"strconv"

	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/models"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
)

// previewPageCount is how many pages a reader sees for free on a locked episode.
const previewPageCount = 3

type ReadingController struct {
	episodeSvc  services.EpisodeService
	trackingSvc services.TrackingService
	unlockSvc   services.UnlockService
	socialSvc   services.SocialService
}

func NewReadingController(
	episodeSvc services.EpisodeService,
	trackingSvc services.TrackingService,
	unlockSvc services.UnlockService,
	socialSvc services.SocialService,
) *ReadingController {
	return &ReadingController{
		episodeSvc:  episodeSvc,
		trackingSvc: trackingSvc,
		unlockSvc:   unlockSvc,
		socialSvc:   socialSvc,
	}
}

func (h *ReadingController) ReadEpisode(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}

	ep, err := h.episodeSvc.GetByID(episodeID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}

	pages, err := h.episodeSvc.GetPages(episodeID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}

	userID := uint64(middleware.GetUserID(c))
	ipAddress := c.ClientIP()
	_ = h.trackingSvc.LogView(episodeID, &userID, ipAddress)

	helper.OK(c, "Episode fetched", gin.H{"episode": ep, "pages": pages})
}

// ReadEpisodeNested serves the reader's episode view at
// GET /reader/series/:id/episodes/:episodeId. It enforces the paywall: premium
// episodes the reader has not unlocked return only a short preview plus metadata.
func (h *ReadingController) ReadEpisodeNested(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("episodeId"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}

	ep, err := h.episodeSvc.GetByID(episodeID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}

	userID := uint64(middleware.GetUserID(c))
	access, err := h.unlockSvc.GetAccess(userID, episodeID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}

	liked, _ := h.socialSvc.IsEpisodeLiked(userID, episodeID)
	likeCount, _ := h.socialSvc.CountEpisodeLikes(episodeID)

	resp := gin.H{
		"locked":         !access.HasAccess(),
		"is_own_episode": access.IsOwn,
		"is_liked":       liked,
		"like_count":     likeCount,
		"episode":        ep,
	}

	pages, _ := h.episodeSvc.GetPages(episodeID)
	if access.HasAccess() {
		ep.Pages = pages
		resp["episode"] = ep
		ipAddress := c.ClientIP()
		_ = h.trackingSvc.LogView(episodeID, &userID, ipAddress)
	} else {
		resp["preview_pages"] = previewPages(pages)
	}

	helper.OK(c, "Episode fetched", resp)
}

// previewPages returns at most previewPageCount pages for a locked episode.
func previewPages(pages []models.Page) []models.Page {
	if len(pages) > previewPageCount {
		return pages[:previewPageCount]
	}
	return pages
}

func (h *ReadingController) UpdateProgress(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}

	var req dto.UpdateProgressRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	userID := uint64(middleware.GetUserID(c))
	if err := h.trackingSvc.UpdateProgress(userID, episodeID, services.UpdateProgressInput{
		LastReadPage:       req.LastReadPage,
		ProgressPercentage: req.ProgressPercentage,
	}); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "Progress saved")
}

func (h *ReadingController) GetHistory(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	histories, total, err := h.trackingSvc.GetReadingHistory(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "History fetched", histories, page, perPage, total)
}
