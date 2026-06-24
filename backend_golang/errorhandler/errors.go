package errorhandler

import "errors"

// ─── Sentinel errors ────────────────────────────────────────────────────────

var (
	ErrNotFound         = errors.New("resource not found")
	ErrUnauthorized     = errors.New("unauthorized")
	ErrForbidden        = errors.New("forbidden")
	ErrBadRequest       = errors.New("bad request")
	ErrConflict         = errors.New("conflict")
	ErrInternalServer   = errors.New("internal server error")
	ErrValidation       = errors.New("validation failed")
	ErrTokenExpired     = errors.New("token has expired")
	ErrTokenInvalid     = errors.New("token is invalid")
	ErrInsufficientCoin = errors.New("insufficient coins")
	ErrAlreadyExists    = errors.New("already exists")
	ErrPaymentFailed    = errors.New("payment processing failed")
)

// AppError is a structured application error carrying an HTTP status code.
type AppError struct {
	Code    int
	Message string
	Err     error
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return e.Err.Error()
	}
	return e.Message
}

func (e *AppError) Unwrap() error { return e.Err }

// ─── Constructors ────────────────────────────────────────────────────────────

func NewNotFound(msg string) *AppError {
	return &AppError{Code: 404, Message: msg, Err: ErrNotFound}
}

func NewUnauthorized(msg string) *AppError {
	if msg == "" {
		msg = "Unauthorized"
	}
	return &AppError{Code: 401, Message: msg, Err: ErrUnauthorized}
}

func NewForbidden(msg string) *AppError {
	if msg == "" {
		msg = "You don't have permission to perform this action"
	}
	return &AppError{Code: 403, Message: msg, Err: ErrForbidden}
}

func NewBadRequest(msg string) *AppError {
	return &AppError{Code: 400, Message: msg, Err: ErrBadRequest}
}

func NewConflict(msg string) *AppError {
	return &AppError{Code: 409, Message: msg, Err: ErrConflict}
}

func NewInternalError(msg string) *AppError {
	if msg == "" {
		msg = "Internal server error"
	}
	return &AppError{Code: 500, Message: msg, Err: ErrInternalServer}
}

func NewInsufficientCoin() *AppError {
	return &AppError{Code: 402, Message: "Insufficient coins to complete this action", Err: ErrInsufficientCoin}
}
