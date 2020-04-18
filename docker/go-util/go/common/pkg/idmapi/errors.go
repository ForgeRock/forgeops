package idmapi

import "errors"

var (
	// ErrIDMBaseURLInvalid notes that idmBaseURL is not in format protocol://host:port/path
	ErrIDMBaseURLInvalid = errors.New("idmBaseURL not in format protocol://host:port/path")

	// ErrIDMAuthenticationFailed notes that IDM username/password authentication failed
	ErrIDMAuthenticationFailed = errors.New("idm authentication failed")

	// ErrUserNameAndPasswordRequired notes that IDM username and password are required
	ErrUserNameAndPasswordRequired = errors.New("idm username and password required")

	// ErrEmailRequired notes that the email address is required
	ErrEmailRequired = errors.New("email required")

	// ErrPasswordRequired notes that password is required
	ErrPasswordRequired = errors.New("password required")

	// ErrIDRequired notes that ID is required
	ErrIDRequired = errors.New("id required")

	// ErrURLPathRequired notes that an IDM URL path is required, which should begin with a forward-slash
	ErrURLPathRequired = errors.New("urlPath required")

	// ErrUnexpectedIDMResponse notes that an IDM returned an unexpected/unhandled HTTP response
	ErrUnexpectedIDMResponse = errors.New("unexpected IDM response")

	// ErrTeamMemberNotFound indicates that the team member ID was not found for an IDM Managed User
	ErrTeamMemberNotFound = errors.New("teammemberID not found")

	// ErrTeamMemberAlreadyExists indicates that the team member ID already exists as an IDM Managed User
	ErrTeamMemberAlreadyExists = errors.New("teammemberID already exists")

	// StatusCodeErrorTemplate is an error template used when client HTTP request received a status
	// code >= 400, without the expected JSON response containing a specific error.
	StatusCodeErrorTemplate = "idm client request failed unexpectedly with status: %v"

	// ErrUserTypeUnknown indicates an unknown user type
	ErrUserTypeUnknown = errors.New("userType is not supported")
)
