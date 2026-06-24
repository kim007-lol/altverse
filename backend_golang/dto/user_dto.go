package dto

type UpdateProfileRequest struct {
	Name            *string `json:"name"             binding:"omitempty,min=2,max=100"`
	PenName         *string `json:"pen_name"         binding:"omitempty,max=100"`
	Bio             *string `json:"bio"              binding:"omitempty,max=500"`
	ThemePreference *string `json:"theme_preference" binding:"omitempty,oneof=dark light"`
}
