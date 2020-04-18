package messaging

import (
	"context"
	"errors"
	"sync"
	"testing"

	"cloud.google.com/go/pubsub"
	"github.com/bxcodec/faker"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/messaging/v2/mocks"
)

type testSubscriptionSuite struct {
	suite.Suite
	lorem faker.DataFaker

	ctx          context.Context
	client       *mocks.Client
	subscription *mocks.Subscription
	topicService *mocks.TopicServicer
}

func (s *testSubscriptionSuite) SetupTest() {
	s.ctx = context.Background()
	s.lorem = faker.GetLorem()
	s.client = &mocks.Client{}
	s.subscription = &mocks.Subscription{}
	s.topicService = &mocks.TopicServicer{}
}

// --------

// In order for 'go test' to run this suite, we need to create
// a normal test function and pass our suite to suite.Run
func TestSubscriptionSuite(t *testing.T) {
	suite.Run(t, new(testSubscriptionSuite))
}

func (s *testSubscriptionSuite) TestEnsureReadySubCreation() {

	s.topicService.On("EnsureExists", s.ctx).Return(nil)

	mockSub := mocks.Subscription{}
	mockSub.On("Exists", s.ctx).Return(false, nil)
	mockClient := mocks.Client{}
	t := &pubsub.Topic{}
	subConfig := pubsub.SubscriptionConfig{Topic: t, AckDeadline: 0}
	mockClient.
		On("CreateSubscription", s.ctx, "", subConfig).
		Return(nil, nil)
	mockClient.On("Topic", "").Return(&pubsub.Topic{})

	sa := &SubscriptionService{
		topicService: s.topicService,
		subscription: &mockSub,
		client:       &mockClient,
		log:          logrus.WithField("pkg", "messaging/v2"),
	}

	err := sa.ensureReady(s.ctx)
	s.NoError(err)
}

func (s *testSubscriptionSuite) TestEnsureReadySubCreationError() {

	s.topicService.On("EnsureExists", s.ctx).Return(nil)

	mockSub := mocks.Subscription{}
	mockSub.On("Exists", s.ctx).Return(false, nil)
	mockClient := mocks.Client{}
	t := &pubsub.Topic{}
	subConfig := pubsub.SubscriptionConfig{Topic: t, AckDeadline: 0}
	mockClient.
		On("CreateSubscription", s.ctx, "", subConfig).
		Return(nil, pubsub.ErrOversizedMessage)
	mockClient.On("Topic", "").Return(&pubsub.Topic{})

	sa := &SubscriptionService{
		topicService: s.topicService,
		subscription: &mockSub,
		client:       &mockClient,
		log:          logrus.WithField("pkg", "messaging/v2"),
	}

	err := sa.ensureReady(s.ctx)
	s.Error(err)
	s.NotNil(sa.subscription)
}

func (s *testSubscriptionSuite) TestEnsureSubscriptionExistsError() {

	s.topicService.On("EnsureExists", s.ctx).Return(nil)

	mockSub := mocks.Subscription{}
	mockSub.On("Exists", s.ctx).Return(true, errors.New(""))

	sa := &SubscriptionService{
		topicService: s.topicService,
		subscription: &mockSub,
		log:          logrus.WithField("pkg", "messaging/v2"),
	}

	err := sa.ensureReady(s.ctx)
	s.Error(err)
}

func (s *testSubscriptionSuite) TestReceiveMessages() {
	s.topicService.On("EnsureExists", s.ctx).Return(nil)

	mockSub := mocks.Subscription{}
	mockSub.On("Exists", s.ctx).Return(true, nil)
	handler := func(context.Context, *pubsub.Message) {}
	mockSub.
		On("Receive", s.ctx, mock.AnythingOfType("func(context.Context, *pubsub.Message)")).
		Return(nil)

	sa := &SubscriptionService{
		topicService: s.topicService,
		subscription: &mockSub,
		log:          logrus.WithField("pkg", "messaging/v2"),
		handler:      handler,
	}
	wg := &sync.WaitGroup{}
	wg.Add(1)
	sa.ReceiveMessages(s.ctx, wg, nil)

	// Ensure waitgroup is zeroed out.
	s.Equal(wg, &sync.WaitGroup{})
}

func (s *testSubscriptionSuite) TestNewSubscriptionFromConfig() {
	topicID := NewTopicID(Name(s.lorem.Word()), NoNamespace)
	subscriptionID := NewSubscriptionID(Name(s.lorem.Word()), NoNamespace)
	client := &mocks.Client{}
	client.On("Subscription", subscriptionID.ID()).Return(&pubsub.Subscription{})
	client.On("Topic", topicID.ID()).Return(&pubsub.Topic{})
	wrappedHandler := func(ctx context.Context, msg *pubsub.Message) error { return nil }
	handler := MessageHandlerFunc(func(ctx context.Context, msg *pubsub.Message) {})
	svcLog := logrus.WithFields(logrus.Fields{
		"pkg":            "messaging",
		"svc":            "SubscriptionService",
		"subscriptionID": subscriptionID,
		"topicID":        topicID.ID(),
	})

	//handler := func(ctx context.Context, msg *pubsub.Message){}
	//cfgBaseline := SubscriptionServiceConfig{}
	tests := []struct {
		name           string
		config         SubscriptionServiceConfig
		opts           []SubscriptionServiceOption
		failureMockOps []mocks.Operation
		expectedVal    *SubscriptionService
		expectedErr    error
	}{
		{
			name: "success: defaults are applied",
			config: SubscriptionServiceConfig{
				Client:         client,
				TopicID:        topicID,
				SubscriptionID: subscriptionID,
				Handler:        nil,
				Options: SubscriptionServiceOptions{
					WrappedHandler: wrappedHandler,
				},
			},
			expectedVal: &SubscriptionService{
				client:          nil,
				topicID:         topicID,
				topicService:    NewTopicService(client, topicID),
				subscriptionID:  subscriptionID,
				subscription:    &pubsub.Subscription{ReceiveSettings: DefaultReceiveSettings},
				handler:         func(ctx context.Context, msg *pubsub.Message) {},
				ackDeadline:     DefaultSubscriptionServiceOpts.AckDeadline,
				log:             svcLog,
				failureStrategy: NewFailureDefault(),
			},
		},
		{
			name: "success: override some receive settings",
			config: SubscriptionServiceConfig{
				Client:         client,
				TopicID:        topicID,
				SubscriptionID: subscriptionID,
				Handler:        nil,
				Options: SubscriptionServiceOptions{
					WrappedHandler:  wrappedHandler,
					FailureStrategy: NewFailureDefault(),
					ReceiveSettings: &pubsub.ReceiveSettings{
						MaxExtension:  10,
						NumGoroutines: 2,
					},
				},
			},
			expectedVal: &SubscriptionService{
				client:         nil,
				topicID:        topicID,
				topicService:   NewTopicService(client, topicID),
				subscriptionID: subscriptionID,
				subscription: &pubsub.Subscription{ReceiveSettings: pubsub.ReceiveSettings{
					MaxExtension:           10,
					NumGoroutines:          2,
					MaxOutstandingMessages: DefaultReceiveSettings.MaxOutstandingMessages,
					MaxOutstandingBytes:    DefaultReceiveSettings.MaxOutstandingBytes,
				}},
				handler:         func(ctx context.Context, msg *pubsub.Message) {},
				ackDeadline:     DefaultSubscriptionServiceOpts.AckDeadline,
				log:             svcLog,
				failureStrategy: NewFailureDefault(),
			},
		},
		{
			name: "success: non-default failure strategy",
			config: SubscriptionServiceConfig{
				Client:         client,
				TopicID:        topicID,
				SubscriptionID: subscriptionID,
				Handler:        nil,
				Options: SubscriptionServiceOptions{
					WrappedHandler:  wrappedHandler,
					FailureStrategy: &MockFailureStrategy{},
					ReceiveSettings: &pubsub.ReceiveSettings{
						MaxExtension:  10,
						NumGoroutines: 2,
					},
				},
			},
			failureMockOps: []mocks.Operation{
				{
					Method:       "ValidateForSubscriptionConfig",
					Params:       []interface{}{mock.Anything},
					ReturnValues: []interface{}{nil},
				},
				{
					Method:       "WrapHandler",
					Params:       []interface{}{mock.Anything, mock.Anything},
					ReturnValues: []interface{}{handler},
				},
			},
			expectedVal: &SubscriptionService{
				client:         nil,
				topicID:        topicID,
				topicService:   NewTopicService(client, topicID),
				subscriptionID: subscriptionID,
				subscription: &pubsub.Subscription{ReceiveSettings: pubsub.ReceiveSettings{
					MaxExtension:           10,
					NumGoroutines:          2,
					MaxOutstandingMessages: DefaultReceiveSettings.MaxOutstandingMessages,
					MaxOutstandingBytes:    DefaultReceiveSettings.MaxOutstandingBytes,
				}},
				handler:         func(ctx context.Context, msg *pubsub.Message) {},
				ackDeadline:     DefaultSubscriptionServiceOpts.AckDeadline,
				log:             svcLog,
				failureStrategy: &MockFailureStrategy{},
			},
		},
		{
			name: "failure: failure strategy validation failed",
			config: SubscriptionServiceConfig{
				Client:         client,
				TopicID:        topicID,
				SubscriptionID: subscriptionID,
				Options: SubscriptionServiceOptions{
					WrappedHandler:  wrappedHandler,
					FailureStrategy: &MockFailureStrategy{},
				},
			},
			failureMockOps: []mocks.Operation{
				{
					Method:       "ValidateForSubscriptionConfig",
					Params:       []interface{}{mock.Anything},
					ReturnValues: []interface{}{errors.New("this config is bad and you should feel bad")},
				},
			},
			expectedVal: nil,
			expectedErr: errors.New("this config is bad and you should feel bad"),
		},
		{
			name: "failure: handler & failure strategy specified",
			config: SubscriptionServiceConfig{
				Client:         client,
				TopicID:        topicID,
				SubscriptionID: subscriptionID,
				Handler:        handler,
				Options: SubscriptionServiceOptions{
					WrappedHandler:  wrappedHandler,
					FailureStrategy: &MockFailureStrategy{},
				},
			},

			expectedVal: nil,
			expectedErr: ErrInvalidHandlerParameterCombination,
		},
		{
			name: "success: opts are applied and override parameters specified in SubscriptionServiceOptions",
			config: SubscriptionServiceConfig{
				Client:         client,
				TopicID:        topicID,
				SubscriptionID: subscriptionID,
				Options: SubscriptionServiceOptions{
					WrappedHandler: nil,
				},
			},
			opts: []SubscriptionServiceOption{
				OptFailureStrategy{&MockFailureStrategy{}},
				OptWrappedHandler(wrappedHandler),
			},
			expectedVal: &SubscriptionService{
				client:          nil,
				topicID:         topicID,
				topicService:    NewTopicService(client, topicID),
				subscriptionID:  subscriptionID,
				subscription:    &pubsub.Subscription{ReceiveSettings: DefaultReceiveSettings},
				handler:         handler,
				ackDeadline:     DefaultSubscriptionServiceOpts.AckDeadline,
				log:             svcLog,
				failureStrategy: &MockFailureStrategy{},
			},
			expectedErr: nil,
		},
	}
	for _, t := range tests {
		s.T().Log(t.name)
		// -----
		// given
		// -----
		svcMocks := []*mock.Mock{}
		mockOps := [][]mocks.Operation{}
		if t.failureMockOps != nil {
			svcMocks = append(svcMocks, &t.config.Options.FailureStrategy.(*MockFailureStrategy).Mock)
			mockOps = append(mockOps, t.failureMockOps)
		}
		for i := range svcMocks {
			for _, op := range mockOps[i] {
				svcMocks[i].On(op.Method, op.Params...).Return(op.ReturnValues...)
			}
		}
		// ----
		// when
		// ----
		var actualVal *SubscriptionService
		var err error
		if t.opts != nil {
			actualVal, err = NewSubscriptionServiceFromConfig(t.config)
		} else {
			actualVal, err = NewSubscriptionServiceFromConfig(t.config, t.opts...)
		}
		// ----
		// then
		// ----
		if t.expectedErr != nil && err != nil {
			s.Contains(err.Error(), t.expectedErr.Error())
		} else {
			s.Equal(t.expectedErr, err)
			s.Equal(actualVal.ackDeadline, t.expectedVal.ackDeadline)
			s.Equal(actualVal.subscriptionID, t.expectedVal.subscriptionID)
			s.Equal(actualVal.topicID, t.expectedVal.topicID)
			s.Equal(actualVal.subscription.(*pubsub.Subscription).ReceiveSettings, t.expectedVal.subscription.(*pubsub.Subscription).ReceiveSettings)
			s.Equal(actualVal.log, t.expectedVal.log)
			s.NotNil(actualVal.handler)
			// If we're mocking the failure strategy,
			// just ensure that what we passed in is actually saved on the service.
			if fs, ok := t.expectedVal.failureStrategy.(*MockFailureStrategy); ok {
				actualVal.failureStrategy = fs
			}
			s.Equal(actualVal.failureStrategy, t.expectedVal.failureStrategy)
		}

		for _, m := range svcMocks {
			m.AssertExpectations(s.T())
		}
	}
}
