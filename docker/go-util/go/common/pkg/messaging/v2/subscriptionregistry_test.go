package messaging

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/messaging/v2/mocks"

	"cloud.google.com/go/pubsub"
	"github.com/bxcodec/faker"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"
)

type testSubscriptionRegistrySuite struct {
	suite.Suite
	lorem faker.DataFaker

	ctx          context.Context
	client       *mocks.Client
	subscription *mocks.Subscription
	topicService *mocks.TopicServicer
}

func (s *testSubscriptionRegistrySuite) SetupTest() {
	s.ctx = context.Background()
	s.lorem = faker.GetLorem()
	s.client = &mocks.Client{}
	s.subscription = &mocks.Subscription{}
	s.topicService = &mocks.TopicServicer{}
}

// --------

// In order for 'go test' to run this suite, we need to create
// a normal test function and pass our suite to suite.Run
func TestSubscriptionRegistrySuite(t *testing.T) {
	suite.Run(t, new(testSubscriptionRegistrySuite))
}

func (s *testSubscriptionRegistrySuite) TestRegister() {
	s.client.On("Subscription", mock.Anything).Return(&pubsub.Subscription{})
	s.client.On("Topic", mock.Anything).Return(&pubsub.Topic{})
	topicID := NewTopicID("testTopicID", NoNamespace)
	subscriptionID := NewSubscriptionID("testSubscriptionID", NoNamespace)
	handler := func(ctx context.Context, msg *pubsub.Message) {}

	reg := NewSubscriptionRegistry(s.client, 5*time.Second)
	s0 := reg.Register(topicID, subscriptionID, handler)
	s.Len(reg.SubscriptionServices(), 1)
	s.Equal(s0, reg.SubscriptionServices()[0])
}

func (s *testSubscriptionRegistrySuite) TestBlockWhileReceivingBlocksIfWGNotDone() {
	errChan := make(chan error)
	defer close(errChan)
	wg := &sync.WaitGroup{}
	wg.Add(1)

	timer_pass := time.NewTimer(1 * time.Second)
	defer timer_pass.Stop()

	// close the waitChan when the blockWhileReceiving stops blocking.
	waitChan := make(chan struct{})
	go func() {
		defer close(waitChan)
		if err := blockWhileReceiving(wg, errChan, true); err != nil {
			s.Fail("unexpected error occurred during blockWhileReceiving")
		}
	}()
	select {
	case <-waitChan:
		s.Fail("blockWhileReceiving didn't block until we told it to stop")
	case <-timer_pass.C:
		// blockWhileReceiving blocked for the duration of the timer delay! yay!
		// Now tell it we're done so it stops blocking.
		wg.Done()
	}

	// Timer to fail the test if blockWhileReceiving doesn't stop blocking.
	timer_fail := time.NewTimer(100 * time.Millisecond)
	defer timer_fail.Stop()

	select {
	case <-waitChan:
		// It stopped when we told it to!
	case <-timer_fail.C:
		s.Fail("failed to stop blocking when wait group completed")
	}
}

func (s *testSubscriptionRegistrySuite) TestBlockWhileReceivingReturnOnErr() {
	errChan := make(chan error)
	defer close(errChan)
	wg := &sync.WaitGroup{}
	wg.Add(1)

	// close the waitChan when the blockWhileReceiving stops blocking.
	waitChan := make(chan struct{})
	var blockErr error
	go func() {
		defer close(waitChan)
		blockErr = blockWhileReceiving(wg, errChan, true)
	}()

	// Timer to fail the test if blockWhileReceiving doesn't stop blocking.
	timer_fail := time.NewTimer(100 * time.Millisecond)
	defer timer_fail.Stop()

	errChan <- errors.New("sending in a fancy error")

	wg.Done()
	select {
	case <-waitChan:
		// It stopped when we told it to!
	case <-timer_fail.C:
		s.Fail("failed to stop blocking when wait group completed")
	}

	s.Error(blockErr)
}

func (s *testSubscriptionRegistrySuite) TestBlockWhileReceivingNoReturnOnErr() {
	errChan := make(chan error)
	defer close(errChan)
	wg := &sync.WaitGroup{}
	wg.Add(1)

	// close the waitChan when the blockWhileReceiving stops blocking.
	waitChan := make(chan struct{})
	var blockErr error = errors.New("this should be replaced by nil when blockWhileReceiving returns")
	go func() {
		defer close(waitChan)
		blockErr = blockWhileReceiving(wg, errChan, false)
	}()

	// Timer to fail the test if blockWhileReceiving doesn't stop blocking.
	timer_fail := time.NewTimer(100 * time.Millisecond)
	defer timer_fail.Stop()

	errChan <- errors.New("sending in a fancy error")

	wg.Done()
	select {
	case <-waitChan:
		// It stopped when we told it to!
	case <-timer_fail.C:
		s.Fail("failed to stop blocking when wait group completed")
	}

	s.NoError(blockErr)
}
