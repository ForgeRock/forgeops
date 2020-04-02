package mailworker

import (
	"context"
	"encoding/json"
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/stretchr/testify/mock"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/pubsubclient"

	"github.com/stretchr/testify/suite"
)

type emailWorkerTestSuite struct {
	suite.Suite
}

var (
	EmailEnvironmentComplete = TemplateName("environment-complete")
)

func TestEmailWorkerSuite(t *testing.T) {
	err := RegisterTemplate(EmailEnvironmentComplete)
	require.NoError(t, err)
	suite.Run(t, &emailWorkerTestSuite{})
}

func (s *emailWorkerTestSuite) TestReceiveMessage() {
	// given
	const configuredSaasUIBaseURL = "http://localhost"
	const customSaasUIBaseURL = "https://example.com"

	message := &SendEmailMessage{
		TemplateName:   EmailVerification,
		RecipientName:  "John Doe",
		RecipientEmail: "john@example.com",
		TemplateData:   map[string]string{"key": "value"},
	}
	messageBytes, _ := json.Marshal(message)

	messageWithCustomSaasUIBaseURL := &SendEmailMessage{
		TemplateName:   EmailEnvironmentComplete,
		RecipientName:  "Jack Black",
		RecipientEmail: "jack@example.com",
		TemplateData:   map[string]string{"saasUIBaseURL": customSaasUIBaseURL},
	}
	messageWithCustomSaasUIBaseURLBytes, _ := json.Marshal(messageWithCustomSaasUIBaseURL)

	var tests = []struct {
		sendTemplateError     error
		messageBytes          []byte
		expectedSaasUIBaseURL string
		expectSuccess         bool
	}{
		// successfully received message
		{nil, messageBytes, configuredSaasUIBaseURL, true},
		// successfully received message, with "saasUIBaseURL" already defined in templateData
		{nil, messageWithCustomSaasUIBaseURLBytes, customSaasUIBaseURL, true},
		// error from mailSender.SendTemplate
		{fmt.Errorf("generic"), messageBytes, configuredSaasUIBaseURL, false},
		// error from json.Unmarshal
		{nil, []byte{}, "", false},
	}

	for _, t := range tests {
		var actualSaasUIBaseURL string

		mailSender := &MockSender{}
		mailSender.
			On("SendTemplate", mock.Anything, mock.Anything, mock.AnythingOfType("int")).
			Run(func(args mock.Arguments) {
				// the saasUIBaseURL field will only be set if not already present in TemplateData
				opts := args.Get(1).(SendEmailMessage)
				actualSaasUIBaseURL = opts.TemplateData["saasUIBaseURL"]
			}).
			Return(t.sendTemplateError)

		worker := &SendEmailWorker{
			defaultTemplateData: map[string]string{"saasUIBaseURL": configuredSaasUIBaseURL},
			mailSender:          mailSender,
		}

		var ackWasCalled bool
		var nackWasCalled bool
		pubsubMessage := &pubsubclient.MockMessagerWithData{}
		pubsubMessage.
			On("Data").
			Return(t.messageBytes).
			On("Ack").
			Run(func(args mock.Arguments) {
				ackWasCalled = true
			}).
			Return().
			On("Nack").
			Run(func(args mock.Arguments) {
				nackWasCalled = true
			}).
			Return()

		// when
		worker.receiveMessage(context.Background(), pubsubMessage)

		// then
		if t.expectSuccess {
			require.True(s.T(), ackWasCalled)
			require.False(s.T(), nackWasCalled)
		} else {
			require.False(s.T(), ackWasCalled)
			require.True(s.T(), nackWasCalled)
		}
		require.Equal(s.T(), t.expectedSaasUIBaseURL, actualSaasUIBaseURL)
	}
}

func (s *emailWorkerTestSuite) TestStartSendEmailWorkerErrors() {
	// given
	ctx := context.Background()
	createTopicError := fmt.Errorf("CreateTopicError")

	mockTopic := &pubsubclient.MockTopicer{}
	mockTopic.
		On("ID").
		Return("someTopicID")

	mockPubSubber := &pubsubclient.MockPubSubber{}
	mockPubSubber.
		On("Topic", mock.Anything).
		Return(mockTopic).
		On("CreateTopic", mock.Anything, mock.Anything).
		Return(nil, createTopicError)

	// when
	errCreateTopic := StartSendEmailWorker(ctx, map[string]string{"saasUIBaseURL": "http://localhost"}, mockPubSubber, nil)

	// then
	require.EqualError(s.T(), errCreateTopic, createTopicError.Error())
}
