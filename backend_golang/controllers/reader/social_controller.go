package reader

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

type SocialController struct {
	socialSvc services.SocialService
	db        *gorm.DB
}

func NewSocialController(socialSvc services.SocialService, db *gorm.DB) *SocialController {
	return &SocialController{socialSvc: socialSvc, db: db}
}

func (h *SocialController) Follow(c *gin.Context) {
	followedID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid user id", nil)
		return
	}
	followerID := uint64(middleware.GetUserID(c))
	if err := h.socialSvc.Follow(followerID, followedID); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "Followed successfully")
}

func (h *SocialController) Unfollow(c *gin.Context) {
	followedID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid user id", nil)
		return
	}
	followerID := uint64(middleware.GetUserID(c))
	_ = h.socialSvc.Unfollow(followerID, followedID)
	helper.NoContent(c, "Unfollowed successfully")
}

// ToggleFollow follows/unfollows :userId for the current user. Returns {following}.
func (h *SocialController) ToggleFollow(c *gin.Context) {
	followedID, err := strconv.ParseUint(c.Param("userId"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid user id", nil)
		return
	}
	followerID := uint64(middleware.GetUserID(c))
	following, err := h.socialSvc.ToggleFollow(followerID, followedID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Follow toggled", gin.H{"following": following})
}

// CheckFollow reports whether the current user follows :userId.
func (h *SocialController) CheckFollow(c *gin.Context) {
	followedID, err := strconv.ParseUint(c.Param("userId"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid user id", nil)
		return
	}
	followerID := uint64(middleware.GetUserID(c))
	following, err := h.socialSvc.IsFollowing(followerID, followedID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Follow status fetched", gin.H{"following": following})
}

// GetMyFollowers lists the current user's followers (self-scoped, no path param).
func (h *SocialController) GetMyFollowers(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	follows, total, err := h.socialSvc.GetFollowers(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Followers fetched", follows, page, perPage, total)
}

// GetMyFollowing lists the authors the current user follows (self-scoped).
func (h *SocialController) GetMyFollowing(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	follows, total, err := h.socialSvc.GetFollowing(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Following fetched", follows, page, perPage, total)
}

func (h *SocialController) GetFollowers(c *gin.Context) {
	userID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid user id", nil)
		return
	}
	page, perPage := controllers.PaginationParams(c)
	follows, total, err := h.socialSvc.GetFollowers(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Followers fetched", follows, page, perPage, total)
}

func (h *SocialController) GetFollowing(c *gin.Context) {
	userID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid user id", nil)
		return
	}
	page, perPage := controllers.PaginationParams(c)
	follows, total, err := h.socialSvc.GetFollowing(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Following fetched", follows, page, perPage, total)
}

func (h *SocialController) Bookmark(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))
	if err := h.socialSvc.Bookmark(userID, seriesID); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "Bookmarked successfully")
}

func (h *SocialController) Unbookmark(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))
	_ = h.socialSvc.Unbookmark(userID, seriesID)
	helper.NoContent(c, "Bookmark removed")
}

func (h *SocialController) GetBookmarks(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	bookmarks, total, err := h.socialSvc.GetBookmarks(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Bookmarks fetched", bookmarks, page, perPage, total)
}

// ToggleBookmark adds/removes a bookmark on :seriesId. Returns {bookmarked}.
func (h *SocialController) ToggleBookmark(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("seriesId"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))
	bookmarked, err := h.socialSvc.ToggleBookmark(userID, seriesID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Bookmark toggled", gin.H{"bookmarked": bookmarked})
}

// CheckBookmark reports whether the current user bookmarked :seriesId.
func (h *SocialController) CheckBookmark(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("seriesId"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))
	bookmarked, err := h.socialSvc.IsBookmarked(userID, seriesID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Bookmark status fetched", gin.H{"bookmarked": bookmarked})
}

func (h *SocialController) ToggleSeriesLike(c *gin.Context) {
	seriesID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid series id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))
	liked, err := h.socialSvc.ToggleSeriesLike(userID, seriesID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Like toggled", gin.H{"liked": liked})
}

func (h *SocialController) ToggleEpisodeLike(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))
	liked, err := h.socialSvc.ToggleEpisodeLike(userID, episodeID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Like toggled", gin.H{"liked": liked})
}

// ToggleEpisodeLikeNested handles the nested reader path
// (reader/series/:id/episodes/:episodeId/like), reading :episodeId.
func (h *SocialController) ToggleEpisodeLikeNested(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("episodeId"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))
	liked, err := h.socialSvc.ToggleEpisodeLike(userID, episodeID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Like toggled", gin.H{"liked": liked})
}

func (h *SocialController) GetComments(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}
	page, perPage := controllers.PaginationParams(c)
	comments, total, err := h.socialSvc.GetComments(episodeID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Paginated(c, "Comments fetched", comments, page, perPage, total)
}

func (h *SocialController) CreateComment(c *gin.Context) {
	episodeID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid episode id", nil)
		return
	}

	var req dto.CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	userID := uint64(middleware.GetUserID(c))
	comment, err := h.socialSvc.CreateComment(userID, services.CreateCommentInput{
		EpisodeID: episodeID,
		ParentID:  req.ParentID,
		Content:   req.Content,
	})
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.Created(c, "Comment posted", comment)
}

func (h *SocialController) DeleteComment(c *gin.Context) {
	commentID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid comment id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))
	if err := h.socialSvc.DeleteComment(commentID, userID); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "Comment deleted")
}

// ToggleCommentLike likes or unlikes a comment. Returns {liked, like_count}.
func (h *SocialController) ToggleCommentLike(c *gin.Context) {
	commentID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid comment id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))

	var existing struct{ Count int }
	h.db.Raw("SELECT COUNT(*) AS count FROM soc_comment_likes WHERE user_id = ? AND comment_id = ?", userID, commentID).Scan(&existing)

	liked := existing.Count == 0
	if liked {
		h.db.Exec("INSERT INTO soc_comment_likes (user_id, comment_id, created_at) VALUES (?, ?, NOW()) ON CONFLICT DO NOTHING", userID, commentID)
	} else {
		h.db.Exec("DELETE FROM soc_comment_likes WHERE user_id = ? AND comment_id = ?", userID, commentID)
	}

	var likeCount int64
	h.db.Raw("SELECT COUNT(*) FROM soc_comment_likes WHERE comment_id = ?", commentID).Scan(&likeCount)
	helper.OK(c, "Comment like toggled", gin.H{"liked": liked, "like_count": likeCount})
}

// GetMyReports returns the current user's own submitted content reports.
func (h *SocialController) GetMyReports(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	offset := (page - 1) * perPage

	type row struct {
		ID         uint64 `gorm:"column:id"          json:"id"`
		TargetType string `gorm:"column:target_type" json:"target_type"`
		TargetID   uint64 `gorm:"column:target_id"   json:"target_id"`
		Reason     string `gorm:"column:reason"      json:"reason"`
		Status     string `gorm:"column:status"      json:"status"`
		CreatedAt  string `gorm:"column:created_at"  json:"created_at"`
	}

	var total int64
	h.db.Table("soc_reports").Where("reporter_id = ?", userID).Count(&total)

	var rows []row
	h.db.Table("soc_reports").
		Select("id, target_type, target_id, reason, status, created_at").
		Where("reporter_id = ?", userID).
		Order("created_at DESC").Offset(offset).Limit(perPage).Scan(&rows)

	lastPage := 1
	if perPage > 0 && total > 0 {
		lastPage = int((total + int64(perPage) - 1) / int64(perPage))
	}

	helper.OK(c, "Reports fetched", gin.H{
		"data": rows,
		"meta": gin.H{"total": total, "page": page, "per_page": perPage, "last_page": lastPage},
	})
}

// DeleteReport removes a report submitted by the current user.
func (h *SocialController) DeleteReport(c *gin.Context) {
	reportID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid report id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))

	result := h.db.Exec("DELETE FROM soc_reports WHERE id = ? AND reporter_id = ?", reportID, userID)
	if result.RowsAffected == 0 {
		helper.NotFound(c, "report not found")
		return
	}
	helper.NoContent(c, "Report deleted")
}

// GetMyComments returns the current user's comments with episode and series context.
func (h *SocialController) GetMyComments(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	offset := (page - 1) * perPage

	type row struct {
		ID            uint64 `gorm:"column:id"             json:"id"`
		Content       string `gorm:"column:content"        json:"content"`
		CreatedAt     string `gorm:"column:created_at"     json:"created_at"`
		EpisodeID     uint64 `gorm:"column:episode_id"     json:"episode_id"`
		EpisodeTitle  string `gorm:"column:episode_title"  json:"episode_title"`
		EpisodeNumber float64 `gorm:"column:episode_number" json:"episode_number"`
		SeriesID      uint64 `gorm:"column:series_id"      json:"series_id"`
		SeriesTitle   string `gorm:"column:series_title"   json:"series_title"`
		SeriesCover   *string `gorm:"column:series_cover"  json:"cover_url"`
	}

	var total int64
	h.db.Table("soc_comments c").
		Joins("JOIN cnt_episodes ep ON ep.id = c.episode_id").
		Joins("JOIN cnt_series s ON s.id = ep.series_id").
		Where("c.user_id = ? AND c.deleted_at IS NULL", userID).
		Count(&total)

	var rows []row
	h.db.Table("soc_comments c").
		Select("c.id, c.content, c.created_at, c.episode_id, ep.title AS episode_title, ep.episode_number, s.id AS series_id, s.title AS series_title, s.cover_url AS series_cover").
		Joins("JOIN cnt_episodes ep ON ep.id = c.episode_id").
		Joins("JOIN cnt_series s ON s.id = ep.series_id").
		Where("c.user_id = ? AND c.deleted_at IS NULL", userID).
		Order("c.created_at DESC").Offset(offset).Limit(perPage).Scan(&rows)

	lastPage := 1
	if perPage > 0 && total > 0 {
		lastPage = int((total + int64(perPage) - 1) / int64(perPage))
	}

	helper.OK(c, "Comments fetched", gin.H{
		"data": rows,
		"meta": gin.H{
			"total":     total,
			"page":      page,
			"per_page":  perPage,
			"last_page": lastPage,
		},
	})
}
