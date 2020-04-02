package httputil

import "errors"

var (
	ErrInvalidID                  = errors.New("invalid ID")
	ErrInvalidJSONPayload         = errors.New("invalid JSON payload")
	ErrQueryFailed                = errors.New("query failed")
	ErrUnexpectedEntityType       = errors.New("unexpected entity type")
	ErrUnexpectedJSONPayloadError = errors.New("unexpected failure to handle JSON payload")
	ErrUnexpectedRequestType      = errors.New("unexpected request type")
	ErrUnexpectedIDType           = errors.New("unexpected id type")
)

// Generic error response
//
// swagger:model errReply
type ErrorResponseBody struct {
	Errors []string `json:"errors,omitempty"`
}

// NewErrorResponse creates an ErrorResponseBody instance from an error
func NewErrorResponse(err error) *ErrorResponseBody {
	return &ErrorResponseBody{
		Errors: MapError(err),
	}
}
