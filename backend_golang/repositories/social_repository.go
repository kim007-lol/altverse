package repositories

import (
	"aureader/backend/models"

	"gorm.io/gorm"
)

type SocialRepository interface {
	Follow(followerID, followedID uint64) error
	Unfollow(followerID, followedID uint64) error
	IsFollowing(followerID, followedID uint64) (bool, error)
	GetFollowers(userID uint64, page, perPage int) ([]models.Follow, int64, error)
	GetFollowing(userID uint64, page, perPage int) ([]models.Follow, int64, error)
	Bookmark(userID, seriesID uint64) error
	Unbookmark(userID, seriesID uint64) error
	IsBookmarked(userID, seriesID uint64) (bool, error)
	GetBookmarks(userID uint64, page, perPage int) ([]models.Bookmark, int64, error)
	LikeSeries(userID, seriesID uint64) error
	UnlikeSeries(userID, seriesID uint64) error
	IsSeriesLiked(userID, seriesID uint64) (bool, error)
	LikeEpisode(userID, episodeID uint64) error
	UnlikeEpisode(userID, episodeID uint64) error
	IsEpisodeLiked(userID, episodeID uint64) (bool, error)
	CountEpisodeLikes(episodeID uint64) (int64, error)
	FindCommentsByEpisodeID(episodeID uint64, page, perPage int) ([]models.Comment, int64, error)
	FindCommentByID(id uint64) (*models.Comment, error)
	CreateComment(comment *models.Comment) error
	UpdateComment(comment *models.Comment) error
	DeleteComment(id uint64) error
}

type socialRepository struct{ db *gorm.DB }

func NewSocialRepository(db *gorm.DB) SocialRepository {
	return &socialRepository{db: db}
}

func (r *socialRepository) Follow(followerID, followedID uint64) error {
	return r.db.Create(&models.Follow{FollowerID: followerID, FollowedID: followedID}).Error
}

func (r *socialRepository) Unfollow(followerID, followedID uint64) error {
	return r.db.Where("follower_id = ? AND followed_id = ?", followerID, followedID).
		Delete(&models.Follow{}).Error
}

func (r *socialRepository) IsFollowing(followerID, followedID uint64) (bool, error) {
	var count int64
	err := r.db.Model(&models.Follow{}).
		Where("follower_id = ? AND followed_id = ?", followerID, followedID).Count(&count).Error
	return count > 0, err
}

func (r *socialRepository) GetFollowers(userID uint64, page, perPage int) ([]models.Follow, int64, error) {
	var follows []models.Follow
	var total int64
	q := r.db.Model(&models.Follow{}).Where("followed_id = ?", userID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Preload("Follower").Offset(offset).Limit(perPage).Find(&follows).Error
	return follows, total, err
}

func (r *socialRepository) GetFollowing(userID uint64, page, perPage int) ([]models.Follow, int64, error) {
	var follows []models.Follow
	var total int64
	q := r.db.Model(&models.Follow{}).Where("follower_id = ?", userID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Preload("Followed").Offset(offset).Limit(perPage).Find(&follows).Error
	return follows, total, err
}

func (r *socialRepository) Bookmark(userID, seriesID uint64) error {
	return r.db.Create(&models.Bookmark{UserID: userID, SeriesID: seriesID}).Error
}

func (r *socialRepository) Unbookmark(userID, seriesID uint64) error {
	return r.db.Where("user_id = ? AND series_id = ?", userID, seriesID).
		Delete(&models.Bookmark{}).Error
}

func (r *socialRepository) IsBookmarked(userID, seriesID uint64) (bool, error) {
	var count int64
	err := r.db.Model(&models.Bookmark{}).
		Where("user_id = ? AND series_id = ?", userID, seriesID).Count(&count).Error
	return count > 0, err
}

func (r *socialRepository) GetBookmarks(userID uint64, page, perPage int) ([]models.Bookmark, int64, error) {
	var bookmarks []models.Bookmark
	var total int64
	q := r.db.Model(&models.Bookmark{}).Where("user_id = ?", userID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Preload("Series").Offset(offset).Limit(perPage).Find(&bookmarks).Error
	return bookmarks, total, err
}

func (r *socialRepository) LikeSeries(userID, seriesID uint64) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&models.SeriesLike{UserID: userID, SeriesID: seriesID}).Error; err != nil {
			return err
		}
		return tx.Model(&models.Series{}).Where("id = ?", seriesID).
			UpdateColumn("total_likes", gorm.Expr("total_likes + 1")).Error
	})
}

func (r *socialRepository) UnlikeSeries(userID, seriesID uint64) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		res := tx.Where("user_id = ? AND series_id = ?", userID, seriesID).Delete(&models.SeriesLike{})
		if res.Error != nil {
			return res.Error
		}
		if res.RowsAffected == 0 {
			return nil
		}
		return tx.Model(&models.Series{}).Where("id = ?", seriesID).
			UpdateColumn("total_likes", gorm.Expr("GREATEST(total_likes - 1, 0)")).Error
	})
}

func (r *socialRepository) IsSeriesLiked(userID, seriesID uint64) (bool, error) {
	var count int64
	err := r.db.Model(&models.SeriesLike{}).
		Where("user_id = ? AND series_id = ?", userID, seriesID).Count(&count).Error
	return count > 0, err
}

func (r *socialRepository) LikeEpisode(userID, episodeID uint64) error {
	return r.db.Create(&models.EpisodeLike{UserID: userID, EpisodeID: episodeID}).Error
}

func (r *socialRepository) UnlikeEpisode(userID, episodeID uint64) error {
	return r.db.Where("user_id = ? AND episode_id = ?", userID, episodeID).
		Delete(&models.EpisodeLike{}).Error
}

func (r *socialRepository) IsEpisodeLiked(userID, episodeID uint64) (bool, error) {
	var count int64
	err := r.db.Model(&models.EpisodeLike{}).
		Where("user_id = ? AND episode_id = ?", userID, episodeID).Count(&count).Error
	return count > 0, err
}

func (r *socialRepository) CountEpisodeLikes(episodeID uint64) (int64, error) {
	var count int64
	err := r.db.Model(&models.EpisodeLike{}).Where("episode_id = ?", episodeID).Count(&count).Error
	return count, err
}

func (r *socialRepository) FindCommentsByEpisodeID(episodeID uint64, page, perPage int) ([]models.Comment, int64, error) {
	var comments []models.Comment
	var total int64
	q := r.db.Model(&models.Comment{}).
		Where("episode_id = ? AND parent_id IS NULL AND deleted_at IS NULL", episodeID)
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	offset := (page - 1) * perPage
	err := q.Preload("User").Preload("Replies.User").
		Order("is_pinned DESC, created_at ASC").Offset(offset).Limit(perPage).Find(&comments).Error
	return comments, total, err
}

func (r *socialRepository) FindCommentByID(id uint64) (*models.Comment, error) {
	var comment models.Comment
	err := r.db.Where("id = ? AND deleted_at IS NULL", id).First(&comment).Error
	return &comment, err
}

func (r *socialRepository) CreateComment(comment *models.Comment) error {
	return r.db.Create(comment).Error
}

func (r *socialRepository) UpdateComment(comment *models.Comment) error {
	return r.db.Save(comment).Error
}

func (r *socialRepository) DeleteComment(id uint64) error {
	return r.db.Model(&models.Comment{}).Where("id = ?", id).
		Update("deleted_at", gorm.Expr("NOW()")).Error
}
