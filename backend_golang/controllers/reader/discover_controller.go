package reader

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"aureader/backend/controllers"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/models"
	"aureader/backend/repositories"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

const (
	fypCacheKey = "fyp:sections"
	fypCacheTTL = 5 * time.Minute
)

type authorCard struct {
	ID         uint64  `json:"id"`
	PenName    *string `json:"pen_name"`
	AvatarURL  *string `json:"avatar_url"`
	AuthorTier string  `json:"author_tier"`
}

type fypSections struct {
	Featured       []models.Series `json:"featured"`
	Trending       []models.Series `json:"trending"`
	Recommended    []models.Series `json:"recommended"`
	NewReleases    []models.Series `json:"new_releases"`
	Latest         []models.Series `json:"latest"`
	PopularAuthors []authorCard    `json:"popular_authors"`
}

type DiscoverController struct {
	seriesSvc   services.SeriesService
	episodeSvc  services.EpisodeService
	trackingSvc services.TrackingService
	socialSvc   services.SocialService
	userRepo    repositories.UserRepository
	rdb         *redis.Client
	db          *gorm.DB
}

func NewDiscoverController(
	seriesSvc services.SeriesService,
	episodeSvc services.EpisodeService,
	trackingSvc services.TrackingService,
	userRepo repositories.UserRepository,
	socialSvc services.SocialService,
	rdb *redis.Client,
	db *gorm.DB,
) *DiscoverController {
	return &DiscoverController{
		seriesSvc:   seriesSvc,
		episodeSvc:  episodeSvc,
		trackingSvc: trackingSvc,
		socialSvc:   socialSvc,
		userRepo:    userRepo,
		rdb:         rdb,
		db:          db,
	}
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

// GetAuthorProfile returns the public profile of an author: their info,
// published series, top supporters, and follow status for the current user.
func (h *DiscoverController) GetAuthorProfile(c *gin.Context) {
	authorID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid author id", nil)
		return
	}
	viewerID := uint64(middleware.GetUserID(c))

	author, err := h.userRepo.FindByID(authorID)
	if err != nil {
		helper.NotFound(c, "author not found")
		return
	}

	series, _, _ := h.seriesSvc.List(repositories.SeriesFilter{
		AuthorID: &authorID, Status: "published", OrderBy: "updated", Page: 1, PerPage: 20,
	})

	// Top supporters: users who spent the most coins on this author's content.
	// Shape: [{user: {id, name, pen_name, avatar_url}, total_spend: int}]
	var rawSupporters []struct {
		UserID     uint64  `gorm:"column:user_id"`
		Name       string  `gorm:"column:name"`
		PenName    *string `gorm:"column:pen_name"`
		AvatarURL  *string `gorm:"column:avatar_url"`
		CoinsSpent int     `gorm:"column:coins_spent"`
	}
	h.db.Table("gam_season_supporters ss").
		Select("ss.user_id, u.name, u.pen_name, u.avatar_url, SUM(ss.coins_spent) AS coins_spent").
		Joins("JOIN usr_users u ON u.id = ss.user_id").
		Where("ss.author_id = ? AND u.deleted_at IS NULL", authorID).
		Group("ss.user_id, u.name, u.pen_name, u.avatar_url").
		Order("coins_spent DESC").Limit(10).Scan(&rawSupporters)

	supporters := make([]gin.H, 0, len(rawSupporters))
	for _, s := range rawSupporters {
		supporters = append(supporters, gin.H{
			"user": gin.H{
				"id":         s.UserID,
				"name":       s.Name,
				"pen_name":   s.PenName,
				"avatar_url": s.AvatarURL,
			},
			"total_spend": s.CoinsSpent,
		})
	}

	// Followers count and author series/view stats.
	var followerCount, seriesCount, totalViews int64
	h.db.Model(&models.Follow{}).Where("followed_id = ?", authorID).Count(&followerCount)
	h.db.Model(&models.Series{}).Where("author_id = ? AND status = 'published' AND deleted_at IS NULL", authorID).Count(&seriesCount)
	h.db.Model(&models.Series{}).
		Where("author_id = ? AND deleted_at IS NULL", authorID).
		Select("COALESCE(SUM(total_views), 0)").Scan(&totalViews)

	isFollowing := false
	isSelf := viewerID == authorID
	if viewerID > 0 && !isSelf {
		isFollowing, _ = h.socialSvc.IsFollowing(viewerID, authorID)
	}

	// Map User fields to the aliased names Flutter expects.
	canCustomizeBanner := author.AuthorTier != "bronze"
	helper.OK(c, "Author profile fetched", gin.H{
		"author": gin.H{
			"id":                    author.ID,
			"name":                  author.Name,
			"username":              author.Name,
			"pen_name":              author.PenName,
			"bio":                   author.Bio,
			"author_bio":            author.Bio,
			"avatar_url":            author.AvatarURL,
			"author_avatar_url":     author.AvatarURL,
			"author_tier":           author.AuthorTier,
			"author_banner_url":     nil,
			"social_links":          author.SocialLinks,
			"author_social_links":   author.SocialLinks,
			"followers_count":       followerCount,
			"series_count":          seriesCount,
			"total_views":           totalViews,
			"is_verified":           false,
			"can_tip":               true,
			"can_customize_banner":  canCustomizeBanner,
		},
		"series":         series,
		"top_supporters": supporters,
		"is_following":   isFollowing,
		"is_self":        isSelf,
	})
}

// Search handles the /reader/search endpoint.
// Query params: q (text), genre (name), sort (trending|popular|new|liked), page, per_page.
// Returns {data: []series, users: []users, meta: pagination}.
func (h *DiscoverController) Search(c *gin.Context) {
	q := c.Query("q")
	genre := c.Query("genre")
	sort := c.Query("sort")
	page, perPage := controllers.PaginationParams(c)

	// Map frontend sort keys to SeriesFilter.OrderBy.
	orderBy := map[string]string{
		"trending": "views",
		"popular":  "views",
		"new":      "newest",
		"liked":    "likes",
	}[sort]

	var genreID *uint64
	if genre != "" && genre != "all" && genre != "All" {
		var g models.Genre
		if err := h.db.Where("name ILIKE ? OR slug ILIKE ?", genre, genre).First(&g).Error; err == nil {
			genreID = &g.ID
		}
	}

	series, total, _ := h.seriesSvc.List(repositories.SeriesFilter{
		Search:  q,
		GenreID: genreID,
		Status:  "published",
		OrderBy: orderBy,
		Page:    page,
		PerPage: perPage,
	})

	// Also search users (readers & authors) by name when a query is given.
	type userCard struct {
		ID        uint64  `json:"id"`
		Name      string  `json:"name"`
		PenName   *string `json:"pen_name"`
		AvatarURL *string `json:"avatar_url"`
		Role      string  `json:"role"`
	}
	var users []userCard
	if q != "" {
		var rawUsers []models.User
		h.db.Where("(name ILIKE ? OR pen_name ILIKE ?) AND deleted_at IS NULL", "%"+q+"%", "%"+q+"%").
			Limit(10).Find(&rawUsers)
		for _, u := range rawUsers {
			users = append(users, userCard{u.ID, u.Name, u.PenName, u.AvatarURL, u.Role})
		}
	}

	lastPage := 1
	if perPage > 0 && total > 0 {
		lastPage = int((total + int64(perPage) - 1) / int64(perPage))
	}

	helper.OK(c, "Search results", gin.H{
		"data":  series,
		"users": users,
		"meta": gin.H{
			"total":     total,
			"page":      page,
			"per_page":  perPage,
			"last_page": lastPage,
		},
	})
}

// GetFYP returns the For-You-Page aggregate used by the reader home screen.
// The 5 global series sections are served from Redis when available (TTL 5 min),
// reducing 20+ sequential DB queries per home screen load to near zero on cache hit.
// continue_reading is always fetched live because it is per-user.
func (h *DiscoverController) GetFYP(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	ctx := context.Background()

	var sections fypSections
	cacheHit := false
	if h.rdb != nil {
		if cached, err := h.rdb.Get(ctx, fypCacheKey).Bytes(); err == nil {
			if jsonErr := json.Unmarshal(cached, &sections); jsonErr == nil {
				cacheHit = true
			}
		}
	}

	if !cacheHit {
		sections.Featured, _, _ = h.seriesSvc.List(repositories.SeriesFilter{Status: "published", OrderBy: "views", Page: 1, PerPage: 5})
		sections.Trending, _, _ = h.seriesSvc.List(repositories.SeriesFilter{Status: "published", OrderBy: "views", Page: 1, PerPage: 10})
		sections.Recommended, _, _ = h.seriesSvc.List(repositories.SeriesFilter{Status: "published", OrderBy: "likes", Page: 1, PerPage: 10})
		sections.NewReleases, _, _ = h.seriesSvc.List(repositories.SeriesFilter{Status: "published", OrderBy: "newest", Page: 1, PerPage: 10})
		sections.Latest, _, _ = h.seriesSvc.List(repositories.SeriesFilter{Status: "published", OrderBy: "updated", Page: 1, PerPage: 10})

		popularAuthors, _ := h.userRepo.FindPopularAuthors(5)
		sections.PopularAuthors = make([]authorCard, 0, len(popularAuthors))
		for _, a := range popularAuthors {
			sections.PopularAuthors = append(sections.PopularAuthors, authorCard{
				ID: a.ID, PenName: a.PenName, AvatarURL: a.AvatarURL, AuthorTier: a.AuthorTier,
			})
		}

		if h.rdb != nil {
			if b, marshalErr := json.Marshal(sections); marshalErr == nil {
				_ = h.rdb.Set(ctx, fypCacheKey, b, fypCacheTTL).Err()
			}
		}
	}

	continueItems := []gin.H{}
	if userID > 0 {
		histories, _, _ := h.trackingSvc.GetReadingHistory(userID, 1, 5)
		for _, entry := range histories {
			if entry.Episode.SeriesID == 0 {
				continue
			}
			continueItems = append(continueItems, gin.H{
				"series_id":      entry.Episode.SeriesID,
				"title":          entry.Episode.Series.Title,
				"cover_url":      entry.Episode.Series.CoverURL,
				"episode_number": entry.Episode.EpisodeNumber,
				"last_episode":   fmt.Sprintf("Episode %.0f", entry.Episode.EpisodeNumber),
			})
		}
	}

	helper.OK(c, "FYP fetched", gin.H{
		"featured":         sections.Featured,
		"trending":         sections.Trending,
		"recommended":      sections.Recommended,
		"new_releases":     sections.NewReleases,
		"latest":           sections.Latest,
		"popular_authors":  sections.PopularAuthors,
		"continue_reading": continueItems,
	})
}

// GetSearchSuggestions returns series titles matching the q query param.
func (h *DiscoverController) GetSearchSuggestions(c *gin.Context) {
	q := c.Query("q")
	if len(q) < 2 {
		helper.OK(c, "Suggestions fetched", gin.H{"data": []string{}})
		return
	}
	var titles []string
	h.db.Model(&models.Series{}).
		Where("title ILIKE ? AND status = 'published' AND deleted_at IS NULL", "%"+q+"%").
		Limit(8).Pluck("title", &titles)
	helper.OK(c, "Suggestions fetched", gin.H{"data": titles})
}

// GetSearchHistory returns an empty list — no persistent search history in this version.
func (h *DiscoverController) GetSearchHistory(c *gin.Context) {
	helper.OK(c, "Search history fetched", gin.H{"data": []any{}})
}

// ClearSearchHistory is a no-op placeholder (200 OK) since history isn't persisted.
func (h *DiscoverController) ClearSearchHistory(c *gin.Context) {
	helper.NoContent(c, "Search history cleared")
}

// GetPublicReaderProfile returns a reader's public profile with follow status.
func (h *DiscoverController) GetPublicReaderProfile(c *gin.Context) {
	targetID, err := strconv.ParseUint(c.Param("userId"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid user id", nil)
		return
	}
	viewerID := uint64(middleware.GetUserID(c))

	target, err := h.userRepo.FindByID(targetID)
	if err != nil {
		helper.NotFound(c, "user not found")
		return
	}

	var followerCount int64
	h.db.Model(&models.Follow{}).Where("followed_id = ?", targetID).Count(&followerCount)

	var followingCount int64
	h.db.Model(&models.Follow{}).Where("follower_id = ?", targetID).Count(&followingCount)

	isFollowing := false
	isSelf := viewerID == targetID
	if viewerID > 0 && !isSelf {
		isFollowing, _ = h.socialSvc.IsFollowing(viewerID, targetID)
	}

	helper.OK(c, "Reader profile fetched", gin.H{
		"id":              target.ID,
		"name":            target.Name,
		"pen_name":        target.PenName,
		"avatar_url":      target.AvatarURL,
		"bio":             target.Bio,
		"level":           target.Level,
		"exp_points":      target.ExpPoints,
		"role":            target.Role,
		"followers_count": followerCount,
		"following_count": followingCount,
		"is_following":    isFollowing,
		"is_self":         isSelf,
	})
}
