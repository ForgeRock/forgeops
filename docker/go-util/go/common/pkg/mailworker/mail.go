package mailworker

import (
	"context"
	"fmt"
	"strings"

	"github.com/sirupsen/logrus"
)

// TemplateName is an enumeration of different kinds of transactional emails.
type TemplateName string

const (
	DefaultI18n = "en-US"

	// template component paths i18n/template-name
	templateBodyText    = "/%s/%s/body.txt.mustache"
	templateBodyHTML    = "/%s/%s/body.html.mustache"
	templateSubjectText = "/%s/%s/subject.mustache"
)

var (
	I18nSupport = map[string]bool{
		DefaultI18n: true,
	}
	// templates contains named references to email templates
	templates = map[TemplateName]bool{}
)

// SendEmailService sends transactional emails via Sendgrid
type SendEmailService struct {
	defaultSenderEmail string
	defaultSenderName  string
	templateRenderer   TemplateRenderer
	mailer             SMTPMail
	log                *logrus.Entry
}

// NewSendEmailService creates a new service for sending emails via Sendgrid.
// When the Sendgrid API key is blank, no emails will be sent (useful for development).
func NewSendEmailService(defaultSenderEmail string, defaultSenderName string, mailer SMTPMail, templateRenderer TemplateRenderer) (*SendEmailService, error) {
	log := logrus.WithFields(logrus.Fields{
		"svc": "SendEmailService",
		"pkg": "mail",
	})
	if len(strings.TrimSpace(defaultSenderEmail)) == 0 {
		return nil, ErrDefaultSenderEmailRequired
	}
	if len(strings.TrimSpace(defaultSenderName)) == 0 {
		return nil, ErrDefaultSenderNameRequired
	}
	if !mailer.IsActive() {
		log.Warn("Server is set to inactive, so email service will log instead of send")
	}
	return &SendEmailService{
		defaultSenderEmail: defaultSenderEmail,
		defaultSenderName:  defaultSenderName,
		templateRenderer:   templateRenderer,
		mailer:             mailer,
		log:                log,
	}, nil
}

// SendTemplate sends templated emails for a given TemplateName with key-value pair substitutions.
// The toName argument is optional. If an error is returned, this means that we were unable to send the email.
func (s *SendEmailService) SendTemplate(ctx context.Context, opts SendEmailMessage, delayInSeconds int) error {
	log := s.log.WithFields(logrus.Fields{
		"func": "SendTemplate",
	})
	if "" == strings.TrimSpace(opts.RecipientEmail) {
		return ErrRecipientEmailRequired
	}

	if "" == opts.TemplateName {
		return fmt.Errorf(TemplateNameUnknown, opts.TemplateName)
	} else if _, exists := templates[opts.TemplateName]; !exists {
		return fmt.Errorf(TemplateNameUnknown, opts.TemplateName)
	}

	if "" == opts.I18n {
		opts.I18n = DefaultI18n
	} else if enabled, exists := I18nSupport[opts.I18n]; !exists || !enabled {
		opts.I18n = DefaultI18n
	}

	subjectFilename := fmt.Sprintf(templateSubjectText, opts.I18n, opts.TemplateName)
	subject, err := s.templateRenderer.RenderFileWithKeyValuePairs(subjectFilename, opts.TemplateData)
	if err != nil {
		return err
	}

	plainTextFilename := fmt.Sprintf(templateBodyText, opts.I18n, opts.TemplateName)
	plainTextContent, err := s.templateRenderer.RenderFileWithKeyValuePairs(plainTextFilename, opts.TemplateData)
	if err != nil {
		return err
	}
	htmlFilename := fmt.Sprintf(templateBodyHTML, opts.I18n, opts.TemplateName)
	htmlContent, err := s.templateRenderer.RenderFileWithKeyValuePairs(htmlFilename, opts.TemplateData)
	if err != nil {
		return err
	}

	if !s.mailer.IsActive() {
		log.
			WithField("plainTextContent", plainTextContent).
			Info("Email service generated this content while disabled.")
		return nil
	}

	m := NewMailMessage()
	m.SetAddressHeader("From", s.defaultSenderEmail, s.defaultSenderName)
	m.SetAddressHeader("To", opts.RecipientEmail, opts.RecipientName)
	if len(opts.BccEmail) > 0 {
		m.SetAddressHeader("Bcc", opts.BccEmail, "")
	}
	m.SetHeader("Subject", subject)
	m.SetBody("text/plain", plainTextContent)
	m.AddAlternative("text/html", htmlContent)

	log.WithFields(logrus.Fields{
		"delayInSeconds": delayInSeconds,
		"templateName":   opts.TemplateName,
	}).Info("Sending Template")

	if err := s.mailer.SendWithDelay(ctx, m, delayInSeconds); err != nil {
		return fmt.Errorf(EmailClientFailedErrorTemplate, err)
	}

	return nil
}

// RegisterTemplate gives mailworker pkg consumers ability to add their own email subjects
func RegisterTemplate(name TemplateName) error {
	if "" == strings.TrimSpace(string(name)) {
		return fmt.Errorf(RegisterTemplateNameInvalid, name)
	}
	templates[name] = true
	return nil
}
