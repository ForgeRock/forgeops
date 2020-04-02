package mail

import (
	"context"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/messaging/v2"
)

const SendEmailTopicName = "sendEmail"

type SendEmailMessage struct {
	EmailKind      string                 `json:"emailKind"`
	RecipientEmail string                 `json:"recipientEmail"`
	RecipientName  string                 `json:"recipientName"`
	BccEmail       string                 `json:"bccEmail"`
	TemplateData   map[string]interface{} `json:"templateData"`
}

type SendMailService struct {
	messaging.PublishService
}

type SendMailServicer interface {
	SendSendEmailTask(context.Context, SendEmailMessage) error
}

func NewSendMailService(c messaging.Client, pubsubNamespace messaging.Namespace) *SendMailService {
	return &SendMailService{
		*messaging.NewPublishServiceSharedClient(c, messaging.NewTopicID(SendEmailTopicName, pubsubNamespace)),
	}
}

func (s *SendMailService) SendSendEmailTask(ctx context.Context, message SendEmailMessage) error {
	if _, err := s.Publish(ctx, message); err != nil {
		return err
	}
	return nil
}
