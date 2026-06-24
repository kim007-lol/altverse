package dto

type CreateSeriesRequest struct {
	Title    string   `json:"title"    binding:"required,min=1,max=512"`
	Synopsis *string  `json:"synopsis"`
	Type     string   `json:"type"     binding:"required,oneof=manga manhwa manhua webtoon novel"`
	GenreIDs []uint64 `json:"genre_ids"`
}

type UpdateSeriesRequest struct {
	Title     *string  `json:"title"     binding:"omitempty,min=1,max=512"`
	Synopsis  *string  `json:"synopsis"`
	CoverURL  *string  `json:"cover_url"`
	BannerURL *string  `json:"banner_url"`
	Status    *string  `json:"status"    binding:"omitempty,oneof=draft ongoing completed hiatus"`
	Type      *string  `json:"type"      binding:"omitempty,oneof=manga manhwa manhua webtoon novel"`
	GenreIDs  []uint64 `json:"genre_ids"`
}

type SeriesListQuery struct {
	Page    int    `form:"page"    binding:"omitempty,min=1"`
	PerPage int    `form:"per_page" binding:"omitempty,min=1,max=50"`
	Status  string `form:"status"`
	Type    string `form:"type"`
	Genre   uint64 `form:"genre_id"`
	Search  string `form:"search"`
}
