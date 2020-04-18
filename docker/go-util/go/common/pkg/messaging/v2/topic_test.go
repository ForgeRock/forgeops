package messaging

import (
	"context"
	"fmt"
	"testing"

	"github.com/bxcodec/faker"
	"github.com/stretchr/testify/suite"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/messaging/v2/mocks"
)

type testTopicSuite struct {
	suite.Suite

	ctx    context.Context
	lorem  faker.DataFaker
	topic  *mocks.Topic
	client *mocks.Client
}

func NewTestingTopicService(c *mocks.Client, t *mocks.Topic) *TopicService {
	return &TopicService{
		Topic:        t,
		TopicCreator: c,
	}
}

func (s *testTopicSuite) SetupTest() {
	s.ctx = context.Background()
	s.lorem = faker.GetLorem()
	s.topic = &mocks.Topic{}
	s.client = &mocks.Client{}
}

func TestTopicSuite(t *testing.T) {
	suite.Run(t, new(testTopicSuite))
}

func (s *testTopicSuite) TestEnsureTopicExistingSuccess() {
	s.topic.On("Exists", s.ctx).Return(true, nil)
	ts := NewTestingTopicService(s.client, s.topic)

	s.client.AssertNotCalled(s.T(), "CreateTopic")
	err := ts.EnsureExists(s.ctx)
	s.NoError(err)
}

func (s *testTopicSuite) TestEnsureTopicNotExistingSuccess() {
	s.topic.On("Exists", s.ctx).Return(false, nil)
	s.topic.On("ID").Return(s.lorem.Word())
	s.client.
		On("CreateTopic", s.ctx, s.topic.ID()).
		Return(nil, nil)

	ts := NewTestingTopicService(s.client, s.topic)
	err := ts.EnsureExists(s.ctx)
	s.NoError(err)
}

func (s *testTopicSuite) TestEnsureTopicExistsError() {
	s.topic.
		On("Exists", s.ctx).
		Return(false, fmt.Errorf("exists error"))
	s.client.AssertNotCalled(s.T(), "CreateTopic")

	ts := NewTestingTopicService(s.client, s.topic)
	err := ts.EnsureExists(s.ctx)
	s.Error(err)
}

func (s *testTopicSuite) TestEnsureTopicCreateError() {
	s.topic.On("Exists", s.ctx).Return(false, nil)
	s.topic.On("ID").Return(s.lorem.Word())
	s.client.
		On("CreateTopic", s.ctx, s.topic.ID()).
		Return(nil, fmt.Errorf("create error"))

	ts := NewTestingTopicService(s.client, s.topic)
	err := ts.EnsureExists(s.ctx)
	s.Error(err)
}
