package mailworker

import "errors"

var (
	// ErrDefaultSenderEmailRequired notes that the default sender email address is required
	ErrDefaultSenderEmailRequired = errors.New("default email-sender address required")

	// ErrDefaultSenderNameRequired notes that the default sender name is required
	ErrDefaultSenderNameRequired = errors.New("default email-sender name required")

	// ErrRecipientEmailRequired notes that the recipient email address is required
	ErrRecipientEmailRequired = errors.New("recipient email-recipient address required")

	// ErrSaasUIBaseURLRequired notes that the SaaS UI Base URL is required
	ErrSaasUIBaseURLRequired = errors.New("saas-ui base URL required")

	// TemplateNameUnknown is an error message template, signaling that a TemplateName is unknown
	TemplateNameUnknown = "unknown email kind: %v"

	// EmailClientFailedErrorTemplate is an error message template, signaling email client failure
	EmailClientFailedErrorTemplate = "email client failed with error: %v"

	RegisterTemplateNameInvalid                = "invalid email kind: %v"
	RegisterEmailSubjectInvalidSubjectTemplate = "invalid email subject: %v"
)
