package token

import (
	"time"

	"github.com/pkg/errors"
)

// TokenKind is an enumeration of different kinds of transaction tokens.
type TokenKind string

const (
	TokenKindPasswordResetRequest TokenKind = "password-reset"
)

var (
	// TokenKinds is a map of all supported TokenKind values.
	TokenKinds = map[TokenKind]struct{}{
		TokenKindPasswordResetRequest: {},
	}
)

// UserType is an enumeration of different types of users.
type UserType string

const (
	// UserTypeEndUser denotes an end user.
	UserTypeEndUser UserType = "end-user"
	// UserTypeTeamMember denotes a team member.
	UserTypeTeamMember UserType = "team-member"
)

var (
	// UserTypes is a map of all supported UserType values.
	UserTypes = map[UserType]struct{}{
		UserTypeEndUser:    {},
		UserTypeTeamMember: {},
	}
)

const defaultExpirationDays = time.Hour * 24 * 30

// DatastoreEntity is a transaction token record.
type DatastoreEntity struct {
	Kind          TokenKind `json:"kind"`
	UserID        string    `json:"userID"`
	UserType      UserType  `json:"userType"`
	CreatedUTC    int64     `json:"createdUTC"`
	ExpirationUTC int64     `json:"expirationUTC"`
	CompletedUTC  int64     `json:"completedUTC"`
}

// TokenEntity represents a DatastoreEntity in the datastore, with the token value included.
type TokenEntity struct {
	Token string `json:"token"`
	DatastoreEntity
}

// IsExpired returns true if transaction token record is expired in relation to current time.
func (e *TokenEntity) IsExpired() bool {
	nowUTC := time.Now().Unix()
	return nowUTC >= e.ExpirationUTC
}

// IsCompleted returns true if transaction token record is marked complete.
func (e *TokenEntity) IsCompleted() bool {
	return e.CompletedUTC > 0
}

func validate(e DatastoreEntity) error {
	// if _, found := TokenKinds[e.Kind]; !found {
	// 	return errors.Wrap(ErrInvalidArgument, unknownTokenKindErrMsg)
	// }
	// if _, found := UserTypes[e.UserType]; !found {
	// 	return errors.Wrap(ErrInvalidArgument, unknownUserTypeErrMsg)
	// }
	if e.UserID == "" {
		return errors.Wrap(ErrInvalidArgument, userIDRequiredErrMsg)
	}
	if e.CreatedUTC < 1 {
		return errors.Wrap(ErrInvalidArgument, createdUTCRequiredErrMsg)
	}
	if e.ExpirationUTC < 1 {
		return errors.Wrap(ErrInvalidArgument, expirationUTCRequiredErrMsg)
	}
	if e.ExpirationUTC < e.CreatedUTC {
		return errors.Wrap(ErrInvalidArgument, expirationUTCOrderErrMsg)
	}
	// If provided, the completion date must be between creation and expiration dates
	if e.CompletedUTC != 0 &&
		(e.CompletedUTC < e.CreatedUTC || e.CompletedUTC > e.ExpirationUTC) {
		return errors.Wrap(ErrInvalidArgument, completedUTCOrderErrMsg)
	}
	return nil
}
