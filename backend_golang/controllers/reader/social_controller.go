package reader

import (
	"strconv"

	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
)

type SocialController struct {
	socialSvc services.SocialService
}

func NewSocialController(socialSvc services.SocialService) *SocialController {
	return &SocialController{socialSvc: socialSvc}
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
