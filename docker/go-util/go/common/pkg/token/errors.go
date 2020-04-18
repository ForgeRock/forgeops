package token

import "github.com/pkg/errors"

var (
	// ErrInvalidArgument indicates that an ARGUMENT is invalid. Use errors.Wrap to indicate which.
	ErrInvalidArgument = errors.New("invalid argument")
	// ErrEntityNotFound indicates record not found
	ErrEntityNotFound = errors.New("entity not found")
	// ErrTokenExpired indicates the token is expired.
	ErrTokenExpired = errors.New(tokenIsExpiredErrMsg)
	// ErrTokenAlreadyComplete indicates the token has already been used.
	ErrTokenAlreadyComplete = errors.New(tokenAlreadyCompletedErrMsg)
)

const (
	userIDRequiredErrMsg        = "userID is required"
	createdUTCRequiredErrMsg    = "createdUTC is required"
	expirationUTCRequiredErrMsg = "expirationUTC is required"
	expirationUTCOrderErrMsg    = "expected CreatedUTC < ExpirationUTC"
	completedUTCOrderErrMsg     = "expected CreatedUTC < CompletedUTC <= ExpirationUTC"
	tokenAlreadyCompletedErrMsg = "token has previously been completed"
	tokenIsExpiredErrMsg        = "token is expired"
)
