package services

import (
	"aureader/backend/errorhandler"
	"aureader/backend/models"
	"aureader/backend/repositories"
)

type CreateCommentInput struct {
	EpisodeID uint64
	ParentID  *uint64
	Content   string
}

type SocialService interface {
	Follow(followerID, followedID uint64) error
	Unfollow(followerID, followedID uint64) error
	ToggleFollow(followerID, followedID uint64) (following bool, err error)
	IsFollowing(followerID, followedID uint64) (bool, error)
	GetFollowers(userID uint64, page, perPage int) ([]models.Follow, int64, error)
	GetFollowing(userID uint64, page, perPage int) ([]models.Follow, int64, error)
	Bookmark(userID, seriesID uint64) error
	Unbookmark(userID, seriesID uint64) error
	ToggleBookmark(userID, seriesID uint64) (bookmarked bool, err error)
	IsBookmarked(userID, seriesID uint64) (bool, error)
	GetBookmarks(userID uint64, page, perPage int) ([]models.Bookmark, int64, error)
	ToggleSeriesLike(userID, seriesID uint64) (liked bool, err error)
	ToggleEpisodeLike(userID, episodeID uint64) (liked bool, err error)
	IsEpisodeLiked(userID, episodeID uint64) (bool, error)
	CountEpisodeLikes(episodeID uint64) (int64, error)
	GetComments(episodeID uint64, page, perPage int) ([]models.Comment, int64, error)
	CreateComment(userID uint64, input CreateCommentInput) (*models.Comment, error)
	DeleteComment(commentID, userID uint64) error
}

type socialService struct {
	socialRepo repositories.SocialRepository
}

func NewSocialService(socialRepo repositories.SocialRepository) SocialService {
	return &socialService{socialRepo: socialRepo}
}

func (s *socialService) Follow(followerID, followedID uint64) error {
	if followerID == followedID {
		return errorhandler.NewBadRequest("cannot follow yourself")
	}
	already, err := s.socialRepo.IsFollowing(followerID, followedID)
	if err != nil {
		return errorhandler.NewInternalError("")
	}
	if already {
		return errorhandler.NewConflict("already following")
	}
	return s.socialRepo.Follow(followerID, followedID)
}

func (s *socialService) Unfollow(followerID, followedID uint64) error {
	return s.socialRepo.Unfollow(followerID, followedID)
}

// ToggleFollow follows when not yet following, unfollows otherwise.
// Returns the resulting follow state.
func (s *socialService) ToggleFollow(followerID, followedID uint64) (bool, error) {
	if followerID == followedID {
		return false, errorhandler.NewBadRequest("cannot follow yourself")
	}
	already, err := s.socialRepo.IsFollowing(followerID, followedID)
	if err != nil {
		return false, errorhandler.NewInternalError("")
	}
	if already {
		return false, s.socialRepo.Unfollow(followerID, followedID)
	}
	return true, s.socialRepo.Follow(followerID, followedID)
}

func (s *socialService) IsFollowing(followerID, followedID uint64) (bool, error) {
	return s.socialRepo.IsFollowing(followerID, followedID)
}

func (s *socialService) GetFollowers(userID uint64, page, perPage int) ([]models.Follow, int64, error) {
	return s.socialRepo.GetFollowers(userID, page, perPage)
}

func (s *socialService) GetFollowing(userID uint64, page, perPage int) ([]models.Follow, int64, error) {
	return s.socialRepo.GetFollowing(userID, page, perPage)
}

func (s *socialService) Bookmark(userID, seriesID uint64) error {
	already, err := s.socialRepo.IsBookmarked(userID, seriesID)
	if err != nil {
		return errorhandler.NewInternalError("")
	}
	if already {
		return errorhandler.NewConflict("already bookmarked")
	}
	return s.socialRepo.Bookmark(userID, seriesID)
}

func (s *socialService) Unbookmark(userID, seriesID uint64) error {
	return s.socialRepo.Unbookmark(userID, seriesID)
}

// ToggleBookmark bookmarks when not yet bookmarked, removes it otherwise.
// Returns the resulting bookmark state.
func (s *socialService) ToggleBookmark(userID, seriesID uint64) (bool, error) {
	already, err := s.socialRepo.IsBookmarked(userID, seriesID)
	if err != nil {
		return false, errorhandler.NewInternalError("")
	}
	if already {
		return false, s.socialRepo.Unbookmark(userID, seriesID)
	}
	return true, s.socialRepo.Bookmark(userID, seriesID)
}

func (s *socialService) IsBookmarked(userID, seriesID uint64) (bool, error) {
	return s.socialRepo.IsBookmarked(userID, seriesID)
}

func (s *socialService) GetBookmarks(userID uint64, page, perPage int) ([]models.Bookmark, int64, error) {
	return s.socialRepo.GetBookmarks(userID, page, perPage)
}

func (s *socialService) ToggleSeriesLike(userID, seriesID uint64) (bool, error) {
	liked, err := s.socialRepo.IsSeriesLiked(userID, seriesID)
	if err != nil {
		return false, errorhandler.NewInternalError("")
	}
	if liked {
		return false, s.socialRepo.UnlikeSeries(userID, seriesID)
	}
	return true, s.socialRepo.LikeSeries(userID, seriesID)
}

func (s *socialService) ToggleEpisodeLike(userID, episodeID uint64) (bool, error) {
	liked, err := s.socialRepo.IsEpisodeLiked(userID, episodeID)
	if err != nil {
		return false, errorhandler.NewInternalError("")
	}
	if liked {
		return false, s.socialRepo.UnlikeEpisode(userID, episodeID)
	}
	return true, s.socialRepo.LikeEpisode(userID, episodeID)
}

func (s *socialService) IsEpisodeLiked(userID, episodeID uint64) (bool, error) {
	return s.socialRepo.IsEpisodeLiked(userID, episodeID)
}

func (s *socialService) CountEpisodeLikes(episodeID uint64) (int64, error) {
	return s.socialRepo.CountEpisodeLikes(episodeID)
}

func (s *socialService) GetComments(episodeID uint64, page, perPage int) ([]models.Comment, int64, error) {
	return s.socialRepo.FindCommentsByEpisodeID(episodeID, page, perPage)
}

func (s *socialService) CreateComment(userID uint64, input CreateCommentInput) (*models.Comment, error) {
	if input.ParentID != nil {
		parent, err := s.socialRepo.FindCommentByID(*input.ParentID)
		if err != nil {
			return nil, errorhandler.NewNotFound("parent comment not found")
		}
		// Only one level of nesting allowed
		if parent.ParentID != nil {
			return nil, errorhandler.NewBadRequest("cannot reply to a reply")
		}
	}

	comment := &models.Comment{
		UserID:    userID,
		EpisodeID: input.EpisodeID,
		ParentID:  input.ParentID,
		Content:   input.Content,
	}
	if err := s.socialRepo.CreateComment(comment); err != nil {
		return nil, errorhandler.NewInternalError("failed to create comment")
	}
	return comment, nil
}

func (s *socialService) DeleteComment(commentID, userID uint64) error {
	comment, err := s.socialRepo.FindCommentByID(commentID)
	if err != nil {
		return errorhandler.NewNotFound("comment not found")
	}
	if comment.UserID != userID {
		return errorhandler.NewForbidden("cannot delete another user's comment")
	}
	return s.socialRepo.DeleteComment(commentID)
}
