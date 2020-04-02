package mailworker

import (
	"context"
	"fmt"
	"testing"

	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

type emailSenderTestSuite struct {
	suite.Suite
}

var (
	EmailVerification = TemplateName("email-verification")
)

func TestEmailSenderSuite(t *testing.T) {
	err := RegisterTemplate(EmailVerification)
	require.NoError(t, err)
	suite.Run(t, &emailSenderTestSuite{})
}

func (s *emailSenderTestSuite) TestInitErrors() {
	// given
	mockRenderer := &MockTemplateRenderer{}
	mockMailer := &MockSMTPMail{}

	// when
	_, emailMissingErr := NewSendEmailService("", "name", mockMailer, mockRenderer)
	_, nameMissingErr := NewSendEmailService("email@example.com", "", mockMailer, mockRenderer)

	// then
	require.EqualError(s.T(), emailMissingErr, ErrDefaultSenderEmailRequired.Error())
	require.EqualError(s.T(), nameMissingErr, ErrDefaultSenderNameRequired.Error())
}

func (s *emailSenderTestSuite) TestSendArgumentErrors() {
	// given
	kv := map[string]string{}
	kind := EmailVerification
	ctx := context.Background()

	mockMailer := &MockSMTPMail{}
	mockMailer.
		On("IsActive").Return(true)

	sender, _ := NewSendEmailService("email@example.com", "name", mockMailer, &MockTemplateRenderer{})

	// when
	errMissingEmail := sender.SendTemplate(ctx, SendEmailMessage{
		RecipientEmail: "",
		RecipientName:  "",
		TemplateData:   kv,
		TemplateName:   kind,
	}, 0)
	errUnknownTemplateName := sender.SendTemplate(ctx, SendEmailMessage{
		RecipientEmail: "bob@example.com",
		RecipientName:  "",
		TemplateData:   kv,
		TemplateName:   TemplateName("unknown"),
	}, 0)

	// then
	require.EqualError(s.T(), errMissingEmail, ErrRecipientEmailRequired.Error())
	require.Error(s.T(), errUnknownTemplateName)
}

func (s *emailSenderTestSuite) TestSend() {
	// given
	kv := map[string]string{}
	kind := EmailVerification
	subjectFilename := fmt.Sprintf(templateSubjectText, DefaultI18n, kind)
	plainTextFilename := fmt.Sprintf(templateBodyText, DefaultI18n, kind)
	htmlFilename := fmt.Sprintf(templateBodyHTML, DefaultI18n, kind)
	ctx := context.Background()

	mockRenderer := &MockTemplateRenderer{}
	mockRenderer.
		On("RenderFileWithKeyValuePairs", subjectFilename, kv).
		Return("This is a subject.", nil).
		On("RenderFileWithKeyValuePairs", plainTextFilename, kv).
		Return("This is a plain text email.", nil).
		On("RenderFileWithKeyValuePairs", htmlFilename, kv).
		Return("<p>This is a html email.</p>", nil)

	mockMailer := &MockSMTPMail{}
	mockMailer.
		On("IsActive").Return(true).
		On("Send", mock.Anything, mock.AnythingOfType("*mail.Message")).Return(nil).
		On("SendWithDelay", mock.Anything, mock.AnythingOfType("*mail.Message"), mock.AnythingOfType("int")).Return(nil)

	sender, _ := NewSendEmailService("email@example.com", "name", mockMailer, mockRenderer)

	// when
	err := sender.SendTemplate(ctx, SendEmailMessage{
		RecipientName:  "Mr. Peabody",
		RecipientEmail: "to@example.com",
		TemplateName:   kind,
		TemplateData:   kv,
	}, 0)

	// then
	require.NoError(s.T(), err)
}
