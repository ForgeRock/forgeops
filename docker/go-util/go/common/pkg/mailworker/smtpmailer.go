package mailworker

import (
	"context"
	"errors"
	"strconv"
	"time"

	"github.com/go-mail/mail"
	"github.com/sirupsen/logrus"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/models/smtp"
)

type MailMessage interface {
	SetAddressHeader(field, address, name string)
	SetHeader(field string, value ...string)
	SetBody(contentType, body string, settings ...mail.PartSetting)
	AddAlternative(contentType, body string, settings ...mail.PartSetting)
}

func NewMailMessage() MailMessage {
	return mail.NewMessage()
}

type SMTPMail interface {
	SendWithDelay(ctx context.Context, m MailMessage, delayInSeconds int) error
	Send(ctx context.Context, m MailMessage) error
	IsActive() bool
}

type SMTPMailer struct {
	smtpServer smtp.Mailserver
}

func NewSMTPMailer(smtpServer smtp.Mailserver) *SMTPMailer {
	return &SMTPMailer{
		smtpServer: smtpServer,
	}
}

func (s *SMTPMailer) ReceiveServerUpdates(smtpUpdates <-chan smtp.Mailserver) {
	for {
		newServer := <-smtpUpdates
		s.smtpServer = newServer
	}
}

func (s *SMTPMailer) SendWithDelay(ctx context.Context, m MailMessage, delayInSeconds int) error {
	msg, ok := m.(*mail.Message)
	if ok {
		if delayInSeconds > 0 {
			sendAt := time.Now().Add(time.Duration(delayInSeconds) * time.Second).Unix()
			delayHeader := "{\"send_at\": " + strconv.FormatInt(sendAt, 10) + " }"
			m.SetHeader("X-SMTPAPI", delayHeader)
		}

		dialer := mail.NewDialer(
			s.smtpServer.Host,
			s.smtpServer.Port,
			s.smtpServer.Username,
			s.smtpServer.Password,
		)

		if s.smtpServer.MandatoryTLS {
			dialer.StartTLSPolicy = mail.MandatoryStartTLS
		}

		logrus.WithFields(logrus.Fields{
			"subject": msg.GetHeader("Subject"),
			"to":      msg.GetHeader("To"),
			"from":    msg.GetHeader("From"),
			"delay":   delayInSeconds,
		}).Info("Sending email")

		return dialer.DialAndSend(msg)
	}

	return errors.New("unexpected type")
}

func (s *SMTPMailer) Send(ctx context.Context, m MailMessage) error {
	return s.SendWithDelay(ctx, m, 0)
}

func (s *SMTPMailer) IsActive() bool {
	if s.smtpServer.Host == "smtp.sendgrid.net" {
		return s.smtpServer.Password != ""
	}
	return true
}
