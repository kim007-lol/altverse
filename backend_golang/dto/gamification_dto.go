package dto

type ClaimMissionRequest struct {
	MissionID uint64 `json:"mission_id" binding:"required"`
}
