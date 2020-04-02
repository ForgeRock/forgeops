package messaging

import (
	"context"
	"math"
	"strconv"
	"testing"
	"time"

	"cloud.google.com/go/pubsub"
	"github.com/bxcodec/faker"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/messaging/v2/mocks"
)

type testFailureRetryBackOff struct {
	suite.Suite
	lorem faker.DataFaker

	ctx          context.Context
	client       *mocks.Client
	subscription *mocks.Subscription
	topicService *mocks.TopicServicer
}

func (s *testFailureRetryBackOff) SetupTest() {
	s.ctx = context.Background()
	s.lorem = faker.GetLorem()
	s.client = &mocks.Client{}
	s.subscription = &mocks.Subscription{}
	s.topicService = &mocks.TopicServicer{}
}

// --------

// In order for 'go test' to run this suite, we need to create
// a normal test function and pass our suite to suite.Run
func TestFailureRetryBackOff(t *testing.T) {
	suite.Run(t, new(testFailureRetryBackOff))
}

func (s *testSubscriptionSuite) TestFailureRetryBackOff() {
	baseConfig := FailureRetryBackOffConfig{
		RePublisher: &mocks.PublisherServicer{},
	}
	svcLog := logrus.WithFields(logrus.Fields{
		"pkg": "messaging/v2",
		"svc": "FailureRetryBackOff",
	})
	baseExpected := &FailureRetryBackOff{
		log:                 svcLog,
		maxAttempts:         FailureRetryBackOffConfigDefaults.MaxAttempts,
		deadLetterPublisher: nil,
		rePublisher:         &mocks.PublisherServicer{},
		backOffDelayInit:    FailureRetryBackOffConfigDefaults.BackOffDelayInit,
		backOffDelayRatio:   FailureRetryBackOffConfigDefaults.BackOffDelayRatio,
		maxSleep:            FailureRetryBackOffConfigDefaults.MaxSleep,
		maxDelay:            FailureRetryBackOffConfigDefaults.MaxDelay,
		msgService:          &MessageService{},
	}

	//handler := func(ctx context.Context, msg *pubsub.Message){}
	//cfgBaseline := SubscriptionServiceConfig{}
	tests := []struct {
		name        string
		config      FailureRetryBackOffConfig
		expectedVal *FailureRetryBackOff
		expectedErr error
	}{
		{
			name:        "success: defaults are applied",
			config:      baseConfig,
			expectedVal: baseExpected,
		},
	}
	for _, t := range tests {
		s.T().Log(t.name)
		// -----
		// given
		// -----
		svcMocks := []*mock.Mock{}
		mockOps := [][]mocks.Operation{}
		for i := range svcMocks {
			for _, op := range mockOps[i] {
				svcMocks[i].On(op.Method, op.Params...).Return(op.ReturnValues...)
			}
		}
		// ----
		// when
		// ----
		actualVal, err := NewFailureRetryBackOff(t.config)

		// ----
		// then
		// ----
		if t.expectedErr != nil && err != nil {
			s.Contains(err.Error(), t.expectedErr.Error())
		} else {
			s.Equal(t.expectedErr, err)
			s.Equal(*t.expectedVal, *actualVal)
		}

		for _, m := range svcMocks {
			m.AssertExpectations(s.T())
		}
	}
}

func (s *testSubscriptionSuite) TestHandleFailure() {
	ctx := context.Background()
	log := logrus.WithField("svc", "test")
	inputErr := errors.New("this is an error")
	baseStrategy := FailureRetryBackOff{
		rePublisher:         &mocks.PublisherServicer{},
		deadLetterPublisher: &mocks.PublisherServicer{},
		msgService:          &mocks.MessageServicer{},
		log:                 log,
		maxAttempts:         FailureRetryBackOffConfigDefaults.MaxAttempts,
		backOffDelayInit:    FailureRetryBackOffConfigDefaults.BackOffDelayInit,
		backOffDelayRatio:   FailureRetryBackOffConfigDefaults.BackOffDelayRatio,
		maxSleep:            FailureRetryBackOffConfigDefaults.MaxSleep,
		maxDelay:            FailureRetryBackOffConfigDefaults.MaxDelay,
	}
	tests := []struct {
		name           string
		inputMsg       *pubsub.Message
		inputErr       error
		strategy       FailureRetryBackOff
		rePublisherOps []mocks.Operation
		deadLetterOps  []mocks.Operation
		msgSvcOps      []mocks.Operation
	}{
		{
			name: "success: out of attempts, dead letter publish",
			inputMsg: &pubsub.Message{
				Attributes: map[string]string{
					string(AttrAttempts): strconv.Itoa(baseStrategy.maxAttempts)}},
			inputErr: inputErr,
			strategy: baseStrategy,
			deadLetterOps: []mocks.Operation{
				{
					Method:       "Publish",
					Params:       []interface{}{ctx, mock.AnythingOfType("*pubsub.Message")},
					ReturnValues: []interface{}{mock.Anything, nil},
				},
			},
			msgSvcOps: []mocks.Operation{
				{
					Method:       "Ack",
					Params:       []interface{}{mock.Anything},
					ReturnValues: []interface{}{},
				},
			},
		},
		{
			name: "success: ack and retry",
			inputMsg: &pubsub.Message{
				Attributes: map[string]string{
					string(AttrAttempts): strconv.Itoa(1)}},
			inputErr: inputErr,
			strategy: baseStrategy,
			rePublisherOps: []mocks.Operation{
				{
					Method:       "Publish",
					Params:       []interface{}{ctx, mock.AnythingOfType("*pubsub.Message")},
					ReturnValues: []interface{}{mock.Anything, nil},
				},
			},
			msgSvcOps: []mocks.Operation{
				{
					Method:       "Ack",
					Params:       []interface{}{mock.Anything},
					ReturnValues: []interface{}{},
				},
			},
		},
		{
			name: "success: ack, dead letter queue not defined",
			inputMsg: &pubsub.Message{
				Attributes: map[string]string{
					string(AttrAttempts): strconv.Itoa(baseStrategy.maxAttempts)}},
			inputErr: inputErr,
			strategy: FailureRetryBackOff{
				rePublisher:       &mocks.PublisherServicer{},
				msgService:        &mocks.MessageServicer{},
				log:               logrus.WithField("svc", "test"),
				maxAttempts:       FailureRetryBackOffConfigDefaults.MaxAttempts,
				backOffDelayInit:  FailureRetryBackOffConfigDefaults.BackOffDelayInit,
				backOffDelayRatio: FailureRetryBackOffConfigDefaults.BackOffDelayRatio,
				maxSleep:          FailureRetryBackOffConfigDefaults.MaxSleep,
				maxDelay:          FailureRetryBackOffConfigDefaults.MaxDelay,
			},
			msgSvcOps: []mocks.Operation{
				{
					Method:       "Ack",
					Params:       []interface{}{mock.Anything},
					ReturnValues: []interface{}{},
				},
			},
		},
		{
			name: "success: ack, republisher not defined",
			inputMsg: &pubsub.Message{
				Attributes: map[string]string{
					string(AttrAttempts): strconv.Itoa(baseStrategy.maxAttempts)}},
			inputErr: inputErr,
			strategy: FailureRetryBackOff{
				rePublisher:       &mocks.PublisherServicer{},
				msgService:        &mocks.MessageServicer{},
				log:               logrus.WithField("svc", "test"),
				maxAttempts:       FailureRetryBackOffConfigDefaults.MaxAttempts,
				backOffDelayInit:  FailureRetryBackOffConfigDefaults.BackOffDelayInit,
				backOffDelayRatio: FailureRetryBackOffConfigDefaults.BackOffDelayRatio,
				maxSleep:          FailureRetryBackOffConfigDefaults.MaxSleep,
				maxDelay:          FailureRetryBackOffConfigDefaults.MaxDelay,
			},
			msgSvcOps: []mocks.Operation{
				{
					Method:       "Ack",
					Params:       []interface{}{mock.Anything},
					ReturnValues: []interface{}{},
				},
			},
		},
	}
	for _, t := range tests {
		s.T().Log(t.name)
		// -----
		// given
		// -----
		svcMocks := []*mock.Mock{
			&t.strategy.rePublisher.(*mocks.PublisherServicer).Mock,
			&t.strategy.msgService.(*mocks.MessageServicer).Mock,
		}
		if t.strategy.deadLetterPublisher != nil {
			svcMocks = append(svcMocks, &t.strategy.deadLetterPublisher.(*mocks.PublisherServicer).Mock)
		}
		mockOps := [][]mocks.Operation{t.rePublisherOps, t.msgSvcOps, t.deadLetterOps}
		for i := range svcMocks {
			for _, op := range mockOps[i] {
				svcMocks[i].On(op.Method, op.Params...).Return(op.ReturnValues...)
			}
		}
		// ----
		// when
		// ----
		t.strategy.handleFailure(t.inputMsg, t.inputErr)

		// ----
		// then
		// ----

		for _, m := range svcMocks {
			m.AssertExpectations(s.T())
		}
	}
}

func (s *testSubscriptionSuite) TestSleepUntilNextAttempt() {
	log := logrus.WithField("svc", "test")
	durationBuffer := 100 * time.Millisecond
	baseStrategy := FailureRetryBackOff{
		log:               log,
		maxAttempts:       10,
		backOffDelayInit:  20 * time.Millisecond,
		backOffDelayRatio: 4,
		maxSleep:          140 * time.Millisecond,
		maxDelay:          300 * time.Millisecond,
	}
	tests := []struct {
		name             string
		attempts         int
		expectedDuration time.Duration
		strategy         FailureRetryBackOff
	}{
		{
			name:             "success: sleep until next",
			expectedDuration: baseStrategy.backOffDelayInit,
			attempts:         1,
			strategy:         baseStrategy,
		},
		{
			name:             "success: sleep maxSleep",
			expectedDuration: baseStrategy.maxSleep,
			attempts:         7,
			strategy:         baseStrategy,
		},
		{
			name:             "success: sleep maxDelay",
			expectedDuration: 200 * time.Millisecond,
			attempts:         7,
			strategy: FailureRetryBackOff{
				log:               log,
				maxAttempts:       baseStrategy.maxAttempts,
				backOffDelayInit:  12 * time.Millisecond,
				backOffDelayRatio: 4,
				maxSleep:          500 * time.Millisecond,
				maxDelay:          200 * time.Millisecond,
			},
		},
	}
	for _, t := range tests {
		s.T().Log(t.name)

		// -----
		// given
		// -----
		msg := &pubsub.Message{
			Attributes: map[string]string{
				string(AttrAttempts): strconv.Itoa(t.attempts),
			},
		}
		msg = t.strategy.updateNextAttemptUTC(msg)
		beforeUTC := time.Now()

		// ----
		// when
		// ----
		err := t.strategy.sleepUntilNextAttempt(msg)
		if t.name == tests[0].name {
			s.NoError(err)
		}

		// ----
		// then
		// ----
		afterUTC := time.Now()
		diff := afterUTC.Sub(beforeUTC)
		s.T().Log("slept for: " + diff.String() + " vs expected: " + t.expectedDuration.String())
		s.True(diff >= t.expectedDuration)
		s.True(diff <= t.expectedDuration+durationBuffer)
	}
}

func (s *testSubscriptionSuite) TestDelayDuration() {
	log := logrus.WithField("svc", "test")

	baseStrategy := FailureRetryBackOff{
		log:               log,
		maxAttempts:       10,
		backOffDelayInit:  20 * time.Millisecond,
		backOffDelayRatio: 2,
		maxSleep:          140 * time.Millisecond,
		maxDelay:          300 * time.Millisecond,
	}
	tests := []struct {
		name        string
		attempts    int
		expectedVal time.Duration
		strategy    FailureRetryBackOff
	}{
		{
			name:        "success: initial",
			expectedVal: baseStrategy.backOffDelayInit,
			attempts:    1,
			strategy:    baseStrategy,
		},
		{
			name:        "success: maxDelay",
			expectedVal: baseStrategy.maxDelay,
			attempts:    7,
			strategy:    baseStrategy,
		},
		{
			name: "success: correct ratio at 3rd attempt",
			expectedVal: baseStrategy.backOffDelayInit * time.Duration(
				math.Pow(baseStrategy.backOffDelayRatio, float64(2))),
			attempts: 3,
			strategy: baseStrategy,
		},
	}
	for _, t := range tests {
		s.T().Log(t.name)
		// when
		actualVal := t.strategy.delayDuration(t.attempts)
		// then
		s.Equal(t.expectedVal, actualVal)
	}
}

func (s *testSubscriptionSuite) TestUpdateNextAttemptUTC() {
	log := logrus.WithField("svc", "test")

	resultBuffer := 50 * time.Millisecond
	baseStrategy := FailureRetryBackOff{
		log:               log,
		maxAttempts:       10,
		backOffDelayInit:  20 * time.Millisecond,
		backOffDelayRatio: 2,
		maxSleep:          140 * time.Millisecond,
		maxDelay:          300 * time.Millisecond,
	}
	tests := []struct {
		name          string
		attempts      int
		priorAttempt  time.Time
		expectedDelay time.Duration
		strategy      FailureRetryBackOff
	}{
		{
			name:          "success: initial",
			expectedDelay: baseStrategy.backOffDelayInit,
			attempts:      1,
			strategy:      baseStrategy,
		},
		{
			name:          "success: maxDelay",
			expectedDelay: baseStrategy.maxDelay,
			attempts:      7,
			strategy:      baseStrategy,
		},
		{
			name: "success: correct ratio at 3rd attempt",
			expectedDelay: baseStrategy.backOffDelayInit * time.Duration(
				math.Pow(baseStrategy.backOffDelayRatio, float64(2))),
			attempts: 3,
			strategy: baseStrategy,
		},
	}
	for _, t := range tests {
		s.T().Log(t.name)

		// given
		msg := &pubsub.Message{
			Attributes: map[string]string{
				string(AttrAttempts): strconv.Itoa(t.attempts),
			},
		}
		if t.attempts != 1 {
			msg.Attributes[string(AttrNextAttemptUTC)] = t.priorAttempt.Format(time.RFC3339Nano)
		}
		beforeUTC := time.Now().UTC()

		// when
		resultMsg := t.strategy.updateNextAttemptUTC(msg)

		// then
		actualVal, err := t.strategy.nextAttemptUTC(resultMsg)
		s.NoError(err)

		// first attempt is a special case (since there was no prior attempt)
		if t.attempts == 1 {
			actualDelay := actualVal.Sub(beforeUTC)
			s.True(actualDelay >= t.expectedDelay)
			s.True(actualDelay <= t.expectedDelay+resultBuffer)
		} else {
			s.Equal(t.expectedDelay, actualVal.Sub(t.priorAttempt))
		}

	}
}

func (s *testSubscriptionSuite) TestValidateForSubscriptionConfig() {
	baseStrategy := FailureRetryBackOff{
		log:               logrus.WithField("svc", "test"),
		maxAttempts:       FailureRetryBackOffConfigDefaults.MaxAttempts,
		backOffDelayInit:  FailureRetryBackOffConfigDefaults.BackOffDelayInit,
		backOffDelayRatio: FailureRetryBackOffConfigDefaults.BackOffDelayRatio,
		maxSleep:          FailureRetryBackOffConfigDefaults.MaxSleep,
		maxDelay:          FailureRetryBackOffConfigDefaults.MaxDelay,
	}
	tests := []struct {
		name               string
		subscriptionConfig SubscriptionServiceConfig
		strategy           FailureRetryBackOff
		expectedResult     error
	}{
		{
			name:     "success: valid",
			strategy: baseStrategy,
			subscriptionConfig: SubscriptionServiceConfig{
				Options: SubscriptionServiceOptions{
					AckDeadline:     DefaultSubscriptionServiceOpts.AckDeadline,
					MessageService:  DefaultSubscriptionServiceOpts.MessageService,
					FailureStrategy: DefaultSubscriptionServiceOpts.FailureStrategy,
					ReceiveSettings: DefaultSubscriptionServiceOpts.ReceiveSettings,
				},
			},
			expectedResult: nil,
		},
		{
			name:     "success: err ack deadline too low",
			strategy: baseStrategy,
			subscriptionConfig: SubscriptionServiceConfig{
				Options: SubscriptionServiceOptions{
					AckDeadline:     1,
					MessageService:  DefaultSubscriptionServiceOpts.MessageService,
					FailureStrategy: DefaultSubscriptionServiceOpts.FailureStrategy,
					ReceiveSettings: &pubsub.ReceiveSettings{
						MaxExtension: 1,
					},
				},
			},
			expectedResult: ErrBackOffDurationAckDeadlineMismatch,
		},
		{
			name:     "success: err ack deadline within unacceptable buffer",
			strategy: baseStrategy,
			subscriptionConfig: SubscriptionServiceConfig{
				Options: SubscriptionServiceOptions{
					AckDeadline:     baseStrategy.delayDuration(baseStrategy.maxAttempts),
					MessageService:  DefaultSubscriptionServiceOpts.MessageService,
					FailureStrategy: DefaultSubscriptionServiceOpts.FailureStrategy,
					ReceiveSettings: &pubsub.ReceiveSettings{
						MaxExtension: 1,
					},
				},
			},
			expectedResult: ErrBackOffDurationAckDeadlineMismatch,
		},
	}
	for _, t := range tests {
		s.T().Log(t.name)

		actualResult := t.strategy.ValidateForSubscriptionConfig(t.subscriptionConfig)

		s.Equal(t.expectedResult, actualResult)

	}
}
