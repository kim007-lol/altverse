package reader

import (
	"strconv"

	"aureader/backend/controllers"
	"aureader/backend/helper"
	"aureader/backend/repositories"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
)

type DiscoverController struct {
	seriesSvc  services.SeriesService
	episodeSvc services.EpisodeService
}

func NewDiscoverController(seriesSvc services.SeriesService, episodeSvc services.EpisodeService) *DiscoverController {
	return &DiscoverController{seriesSvc: seriesSvc, episodeSvc: episodeSvc}
}

func (h *DiscoverController) ListSeries(c *gin.Context) {
	page, perPage := controllers.PaginationParams(c)

	var genreID *uint64
	if g := c.Query("genre_id"); g != "" {
		if id, err := strconv.ParseUint(g, 10, 64); err == nil {
			genreID = &id
		}
	}

	series, total, err := h.seriesSvc.List(repositories.SeriesFilter{
		Status:  c.Query("status"),
		Type:    c.Query("type"),
		Search:  c.Query("search"),
		GenreID: genreID,
		Page:    page,
		PerPage: perPage,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Series fetched", series, page, perPage, total)
}

// GetSeries resolves a series by numeric id or by slug (the :id path param
// carries either — Flutter sends numeric ids, older links send slugs).
func (h *DiscoverController) GetSeries(c *gin.Context) {
	param := c.Param("id")
	var (
		series any
		err    error
	)
	if id, parseErr := strconv.ParseUint(param, 10, 64); parseErr == nil {
		series, err = h.seriesSvc.GetByID(id)
	} else {
		series, err = h.seriesSvc.GetBySlug(param)
	}
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Series fetched", series)
}

func (h *DiscoverController) ListEpisodes(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}
	page, perPage := controllers.PaginationParams(c)
	episodes, total, err := h.episodeSvc.ListBySeries(seriesID, true, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Episodes fetched", episodes, page, perPage, total)
}

func (h *DiscoverController) ListGenres(c *gin.Context) {
	genres, err := h.seriesSvc.ListGenres()
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Genres fetched", genres)
}
