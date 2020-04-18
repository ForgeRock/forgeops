package template

import (
	"html"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/markdown"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/models/key"
	"github.com/cbroglie/mustache"
)

const (
	AppUserAccountLocked     string = "account-locked-email"
	AppUserEmailUpdated      string = "email-update-successful"
	AppUserOneTimePasscode   string = "one-time-passcode"
	AppUserPasswordForgot    string = "forgot-password"
	AppUserPasswordReset     string = "reset-password"
	AppUserRecoverUsername   string = "recover-username"
	AppUserRegistration      string = "registration"
	AppUserUsernameRecovered string = "username-recovered"
	AppUserWelcome           string = "welcome"
)

//nolint
// email template model, maps to EmailTemplate (kind) in datastore
//
// swagger:model emailTemplate
type DatastoreEntity struct {
	// datastore entity id
	key.Key
	// required: true
	Body string `json:"body" binding:"required" fm:"content"`
	// required: true
	BodyRendered string `json:"bodyRendered" binding:"required"`
	Description  string `json:"description"`
	Enabled      bool   `json:"enabled" yaml:"enabled"`
	// required: true
	From string `json:"from" yaml:"from" binding:"required"`
	// required: true
	FromAddress string `json:"fromAddress" yaml:"fromAddress" binding:"required"`
	I18n        string `json:"i18n" yaml:"i18n"`
	Name        string `json:"name" yaml:"name"`
	// required: true
	Styles string `json:"styles" binding:"required"`
	// required: true
	Subject string `json:"subject" yaml:"subject" binding:"required"`
	// required: true
	Type        string `json:"type" yaml:"type" binding:"required"`
	URLLifetime int64  `json:"urlLifetime" yaml:"urlLifetime"`
}

// Render runs context through mustache and returns by value with rendered fields
func (t DatastoreEntity) Render(context map[string]interface{}) (DatastoreEntity, error) {
	body, err := mustache.Render(t.Body, context)
	if err != nil {
		return t, err
	}
	body = html.UnescapeString(body)
	t.Body = markdown.Strip(body, true)

	t.BodyRendered, err = mustache.Render(t.BodyRendered, context)
	if err != nil {
		return t, err
	}

	t.From, err = mustache.Render(t.From, context)
	if err != nil {
		return t, err
	}

	t.FromAddress, err = mustache.Render(t.FromAddress, context)
	if err != nil {
		return t, err
	}

	t.Subject, err = mustache.Render(t.Subject, context)
	if err != nil {
		return t, err
	}

	return t, nil
}
