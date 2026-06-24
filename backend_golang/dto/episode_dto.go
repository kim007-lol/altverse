package dto

type CreateEpisodeRequest struct {
	Title         string   `json:"title"          binding:"required,min=1,max=512"`
	EpisodeNumber float64  `json:"episode_number" binding:"omitempty,min=0"`
	CoinPrice     int      `json:"coin_price"     binding:"omitempty,min=0"`
	IsPremium     *bool    `json:"is_premium"`
	ImageURLs     []string `json:"image_urls"`
}

type UpdateEpisodeRequest struct {
	Title         *string  `json:"title"          binding:"omitempty,min=1,max=512"`
	EpisodeNumber *float64 `json:"episode_number" binding:"omitempty,min=0"`
	CoinPrice     *int     `json:"coin_price"     binding:"omitempty,min=0"`
	IsPremium     *bool    `json:"is_premium"`
	Status        *string  `json:"status"         binding:"omitempty,oneof=draft published scheduled"`
	ImageURLs     []string `json:"image_urls"`
}

// ResolvePrice maps the (is_premium, coin_price) pair to an effective coin price:
// an explicit is_premium=false forces the price to zero (free episode).
func (r UpdateEpisodeRequest) ResolvePrice() *int {
	if r.IsPremium != nil && !*r.IsPremium {
		zero := 0
		return &zero
	}
	return r.CoinPrice
}

// ResolvePrice returns the effective coin price for a new episode.
func (r CreateEpisodeRequest) ResolvePrice() int {
	if r.IsPremium != nil && !*r.IsPremium {
		return 0
	}
	return r.CoinPrice
}

type UpdateProgressRequest struct {
	LastReadPage       int     `json:"last_read_page"       binding:"required,min=1"`
	ProgressPercentage float64 `json:"progress_percentage"  binding:"min=0,max=100"`
}
