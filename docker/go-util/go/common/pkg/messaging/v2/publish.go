package messaging

import (
	"context"
	"encoding/json"

	"cloud.google.com/go/pubsub"
	"google.golang.org/api/option"
)

// Publish Service
type PublishService struct {
	topicService TopicServicer
	waiter       PublishResultWaiter
}

func NewPublishService(ctx context.Context, topicID TopicID, projectID string, opts ...option.ClientOption) (*PublishService, error) {
	c, err := pubsub.NewClient(ctx, projectID, opts...)
	if err != nil {
		return nil, err
	}
	return NewPublishServiceSharedClient(c, topicID), nil
}

func NewPublishServiceSharedClient(c Client, topicID TopicID) *PublishService {
	t := NewTopicService(c, topicID)
	return &PublishService{
		topicService: t,
		waiter:       &messageResultWaiter{},
	}
}

// Publishes a message to a given pubsub topic.
// The `msg` parameter must be a json marshal-able object.
func (p *PublishService) Publish(ctx context.Context, data interface{}) (string, error) {
	if err := p.topicService.EnsureExists(ctx); err != nil {
		return "", err
	}

	// This allows for using Publish with data being either:
	//  - raw marshallable json data
	//  - an instance of *pubsub.Message
	msg, ok := data.(*pubsub.Message)
	if !ok {
		msgJson, err := json.Marshal(data)
		if err != nil {
			return "", err
		}
		msg = &pubsub.Message{Data: msgJson}
	}

	result := p.topicService.Publish(ctx, msg)
	return p.waiter.WaitForResult(ctx, result)
}

//
// -----------------

// A Waiter service
type messageResultWaiter struct{}

// Block until the Result is returned and a server-generated
// ID is returned for the published message.
func (_ messageResultWaiter) WaitForResult(ctx context.Context, result *pubsub.PublishResult) (string, error) {
	return result.Get(ctx)
}
