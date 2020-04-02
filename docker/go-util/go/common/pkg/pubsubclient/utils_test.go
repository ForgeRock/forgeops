package pubsubclient

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"
)

var (
	// these are GRPC errors used by the real pubsub client
	errAlreadyExists    = status.Error(codes.AlreadyExists, "already exists")
	errPermissionDenied = status.Error(codes.PermissionDenied, "permission denied")
)

type utilsTestSuite struct {
	suite.Suite
}

func TestPubSubUtilsSuite(t *testing.T) {
	suite.Run(t, &utilsTestSuite{})
}

func (s utilsTestSuite) TestEnsureTopic() {
	// given
	var tests = []struct {
		topicID          string
		createTopicError error
		expectedError    error
	}{
		{"newTopicCreated", nil, nil},
		{"topicAlreadyExists", errAlreadyExists, nil},
		{"unexpectedError", errPermissionDenied, errPermissionDenied},
	}

	for _, t := range tests {
		mockTopic := &MockTopicer{}
		mockTopic.
			On("ID").
			Return(t.topicID)

		mockPubSubber := &MockPubSubber{}
		mockPubSubber.
			On("Topic", mock.Anything).
			Return(mockTopic).
			On("CreateTopic", mock.Anything, t.topicID).
			Return(nil, t.createTopicError)

		// when
		topic, actualError := EnsureTopic(t.topicID, mockPubSubber)

		// then
		if t.expectedError != nil {
			require.Nil(s.T(), topic)
			require.EqualError(s.T(), actualError, t.expectedError.Error())
		} else {
			require.NotNil(s.T(), topic)
			require.NoError(s.T(), actualError)
		}
	}
}

func (s utilsTestSuite) TestSubscribeToTopic() {
	// given
	var tests = []struct {
		subscriptionName        string
		createSubscriptionError error
		receiveError            error
		expectedError           error
		excpectedReceiverCalled bool
	}{
		{"subscriptionCreated", nil, nil, nil, true},
		{"subscriptionAlreadyExists", errAlreadyExists, nil, nil, true},
		{"unexpectedCreateSubscriptionError", errPermissionDenied, nil, errPermissionDenied, false},
		{"unexpectedReceiveError", nil, errPermissionDenied, errPermissionDenied, false},
	}

	var actualReceiverCalled bool
	receiver := func(ctx context.Context, msg Messager) {
		actualReceiverCalled = true
	}

	for _, t := range tests {
		actualReceiverCalled = false

		mockSubscription := &MockSubscriptioner{}
		mockSubscription.
			On("Receive", mock.Anything, mock.Anything).
			Run(func(args mock.Arguments) {
				if t.receiveError == nil {
					// invoke receiver function to simulate message received
					f := args.Get(1).(func(context.Context, Messager))
					f(nil, nil)
				}
			}).
			Return(t.receiveError)

		mockPubSubber := &MockPubSubber{}
		mockPubSubber.
			On("Subscription", t.subscriptionName).
			Return(mockSubscription).
			On("CreateSubscription", mock.Anything, t.subscriptionName, mock.Anything).
			Return(nil, t.createSubscriptionError)

		// when
		actualError := SubscribeToTopic(context.Background(), false, 1, t.subscriptionName, mockPubSubber, &MockTopicer{}, receiver)

		// then
		if t.expectedError != nil {
			require.EqualError(s.T(), actualError, t.expectedError.Error())
		} else {
			require.NoError(s.T(), actualError)
		}
		require.Equal(s.T(), t.excpectedReceiverCalled, actualReceiverCalled)
	}
}
