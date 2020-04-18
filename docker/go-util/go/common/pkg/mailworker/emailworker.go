package mailworker

import (
	"context"
	"encoding/json"
	"time"

	"cloud.google.com/go/pubsub"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/pubsubclient"
	log "github.com/sirupsen/logrus"
)

const (
	sendEmailTopicName        = "sendEmail"
	sendEmailSubscriptionName = "saasWorkerSendEmail"
	sendEmailAckTimeout       = 2 * time.Minute
)

type SendEmailMessage struct {
	I18n           string            `json:"i18n"`
	TemplateName   TemplateName      `json:"emailKind"`
	RecipientEmail string            `json:"recipientEmail"`
	RecipientName  string            `json:"recipientName"`
	BccEmail       string            `json:"bccEmail"`
	TemplateData   map[string]string `json:"templateData"`
}

// SendEmailWorker sends transactional emails.
type SendEmailWorker struct {
	defaultTemplateData map[string]string
	mailSender          Sender
}

// StartSendEmailWorker creates a new SendEmailWorker and bootstraps the pubsub subscription.
func StartSendEmailWorker(
	ctx context.Context,
	defaultTemplateData map[string]string,
	pubsubClient pubsubclient.PubSubber,
	mailSender Sender,
) error {

	sendEmailTopic, err := pubsubclient.EnsureTopic(sendEmailTopicName, pubsubClient)
	if err != nil {
		return err
	}
	s := &SendEmailWorker{
		defaultTemplateData: defaultTemplateData,
		mailSender:          mailSender,
	}

	// start worker goroutine
	err = pubsubclient.SubscribeToTopic(
		ctx,
		true,
		sendEmailAckTimeout,
		sendEmailSubscriptionName,
		pubsubClient,
		sendEmailTopic,
		s.receiveMessage)
	if err != nil {
		return err
	}
	log.Debug("Email sending subscription ended")

	return nil
}

func (s SendEmailWorker) receiveMessage(ctx context.Context, pubsubMsg pubsubclient.Messager) {
	log := log.WithFields(
		log.Fields{
			"pkg":  "mailworker",
			"func": "receiveMessage"})

	// decode JSON message
	sendEmailMsg := SendEmailMessage{}
	var msgData []byte
	if x, ok := pubsubMsg.(*pubsub.Message); ok {
		// production code path
		msgData = x.Data
	} else if x, ok := pubsubMsg.(pubsubclient.MessagerWithData); ok {
		// this is how we fully mock the pubsubMsg in tests
		msgData = x.Data()
	} else {
		log.Errorf("unexpected pubsubclient.Messager implementation: %#v", pubsubMsg)
		pubsubMsg.Nack()
		return
	}
	err := json.Unmarshal(msgData, &sendEmailMsg)
	if err != nil {
		log.Errorf("Could not decode message: %+v", pubsubMsg)
		pubsubMsg.Nack()
		return
	}

	log = log.WithField("payload", string(msgData))

	// add additional fields to template data
	for k, v := range s.defaultTemplateData {
		putIfNotFound(k, v, sendEmailMsg.TemplateData)
	}

	err = s.mailSender.SendTemplate(ctx, sendEmailMsg, 0)
	if err != nil {
		log.Errorf("Failed to send email for message: %+v \nbecause of error: %+v", pubsubMsg, err)
		pubsubMsg.Nack()
		return
	}

	log.Debugf("PubSub Message Handled: %+v", pubsubMsg)
	pubsubMsg.Ack()
}

// putIfNotFound will add additional fields to template data, but only if not already set
func putIfNotFound(key string, value string, m map[string]string) bool {
	if _, found := m[key]; !found {
		m[key] = value
		return true
	}
	return false
}
