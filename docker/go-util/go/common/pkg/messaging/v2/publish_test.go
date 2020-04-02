package messaging

import (
	"context"
	"errors"
	"testing"

	"cloud.google.com/go/pubsub"
	"github.com/bxcodec/faker"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/messaging/v2/mocks"
)

func NewTestingPublishService(t TopicServicer, g PublishResultWaiter) *PublishService {
	return &PublishService{
		topicService: t,
		waiter:       g,
	}
}

type testPublisherSuite struct {
	suite.Suite
	lorem        faker.DataFaker
	ctx          context.Context
	client       *mocks.Client
	topicService *mocks.TopicServicer
	resultWaiter *mocks.PublishResultWaiter
}

func (s *testPublisherSuite) SetupTest() {
	s.ctx = context.Background()
	s.lorem = faker.GetLorem()
	s.client = &mocks.Client{}
	s.topicService = &mocks.TopicServicer{}
	s.resultWaiter = &mocks.PublishResultWaiter{}
}

func TestPublisherSuite(t *testing.T) {
	suite.Run(t, new(testPublisherSuite))
}

func (s *testPublisherSuite) TestPublish() {

	s.topicService.
		On("EnsureExists", s.ctx).
		Return(nil)
	s.topicService.
		On("Publish", s.ctx, mock.Anything).
		Return(&pubsub.PublishResult{})
	s.resultWaiter.
		On("WaitForResult", s.ctx, mock.AnythingOfType("*pubsub.PublishResult")).
		Return(s.lorem.Word(), nil)

	pa := NewTestingPublishService(s.topicService, s.resultWaiter)

	_, err := pa.Publish(s.ctx, mock.Anything)
	s.NoError(err)
}

func (s *testPublisherSuite) TestErrOnEnsureExists() {
	s.topicService.
		On("EnsureExists", s.ctx).
		Return(errors.New(""))
	s.topicService.
		AssertNotCalled(s.T(), "Publish", s.ctx, mock.Anything)

	pa := NewTestingPublishService(s.topicService, s.resultWaiter)

	_, err := pa.Publish(s.ctx, mock.Anything)
	s.Error(err)
}

func (s *testPublisherSuite) TestWaitForResult() {
	s.topicService.
		On("EnsureExists", s.ctx).
		Return(errors.New(""))
	s.topicService.
		AssertNotCalled(s.T(), "Publish", s.ctx, mock.Anything)

	pa := NewTestingPublishService(s.topicService, s.resultWaiter)

	_, err := pa.Publish(s.ctx, mock.Anything)
	s.Error(err)
}
