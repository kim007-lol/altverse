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

type SeriesController struct {
	seriesSvc services.SeriesService
}

func NewSeriesController(seriesSvc services.SeriesService) *SeriesController {
	return &SeriesController{seriesSvc: seriesSvc}
}

func (h *SeriesController) ListMySeries(c *gin.Context) {
	authorID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	series, total, err := h.seriesSvc.ListByAuthor(authorID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Series fetched", series, page, perPage, total)
}

func (h *SeriesController) CreateSeries(c *gin.Context) {
	var req dto.CreateSeriesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	authorID := uint64(middleware.GetUserID(c))
	series, err := h.seriesSvc.Create(authorID, services.CreateSeriesInput{
		Title:    req.Title,
		Synopsis: req.Synopsis,
		Type:     req.Type,
		GenreIDs: req.GenreIDs,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Created(c, "Series created", series)
}

func (h *SeriesController) UpdateSeries(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}

	var req dto.UpdateSeriesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	authorID := uint64(middleware.GetUserID(c))
	series, err := h.seriesSvc.Update(seriesID, authorID, services.UpdateSeriesInput{
		Title:     req.Title,
		Synopsis:  req.Synopsis,
		CoverURL:  req.CoverURL,
		BannerURL: req.BannerURL,
		Status:    req.Status,
		Type:      req.Type,
		GenreIDs:  req.GenreIDs,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Series updated", series)
}

// PublishSeries sets a series status to "published" (POST /author/series/:id/publish).
func (h *SeriesController) PublishSeries(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}
	authorID := uint64(middleware.GetUserID(c))
	published := "published"
	series, err := h.seriesSvc.Update(seriesID, authorID, services.UpdateSeriesInput{
		Status: &published,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Series published", series)
}

func (h *SeriesController) DeleteSeries(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}

	authorID := uint64(middleware.GetUserID(c))
	if err := h.seriesSvc.Delete(seriesID, authorID); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "Series deleted")
}
