package mailworker

import "context"

// Sender is a service that sends emails.
type Sender interface {
	// SendTemplate sends templated emails for a given TemplateName with key-value pair substitutions.
	// If an error is returned, this means that we were unable to send the email.
	SendTemplate(context.Context, SendEmailMessage, int) error
}

// TemplateRenderer renders string templates.
type TemplateRenderer interface {
	// RenderFileWithKeyValuePairs renders a template-file with the given key-value pairs for replacing fields.
	RenderFileWithKeyValuePairs(filename string, templateData map[string]string) (string, error)
}
