package author

import (
	"strconv"

	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
)

type EpisodeController struct {
	episodeSvc services.EpisodeService
}

func NewEpisodeController(episodeSvc services.EpisodeService) *EpisodeController {
	return &EpisodeController{episodeSvc: episodeSvc}
}

func (h *EpisodeController) ListEpisodes(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}
	page, perPage := controllers.PaginationParams(c)
	episodes, total, err := h.episodeSvc.ListBySeries(seriesID, false, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Episodes fetched", episodes, page, perPage, total)
}

func (h *EpisodeController) CreateEpisode(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}

	var req dto.CreateEpisodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	authorID := uint64(middleware.GetUserID(c))
	ep, err := h.episodeSvc.Create(seriesID, authorID, services.CreateEpisodeInput{
		Title:         req.Title,
		EpisodeNumber: req.EpisodeNumber,
		PriceCoins:    req.ResolvePrice(),
		ImageURLs:     req.ImageURLs,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Created(c, "Episode created", ep)
}

func (h *EpisodeController) UpdateEpisode(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}

	var req dto.UpdateEpisodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	authorID := uint64(middleware.GetUserID(c))
	ep, err := h.episodeSvc.Update(episodeID, authorID, services.UpdateEpisodeInput{
		Title:         req.Title,
		EpisodeNumber: req.EpisodeNumber,
		PriceCoins:    req.ResolvePrice(),
		Status:        req.Status,
		ImageURLs:     req.ImageURLs,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Episode updated", ep)
}

func (h *EpisodeController) PublishEpisode(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}
	authorID := uint64(middleware.GetUserID(c))
	if err := h.episodeSvc.Publish(episodeID, authorID); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "Episode published")
}

func (h *EpisodeController) DeleteEpisode(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}
	authorID := uint64(middleware.GetUserID(c))
	if err := h.episodeSvc.Delete(episodeID, authorID); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "Episode deleted")
}
