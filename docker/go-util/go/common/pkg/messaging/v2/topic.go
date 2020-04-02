package messaging

import (
	"context"

	"github.com/pkg/errors"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// TopicID defines a namespaced reference to a GCP PubSub topic
type TopicID struct {
	name      Name
	namespace Namespace
}

// NewTopicID creates a new TopicID
// Use the NoNamespace const if name-spacing is not required
func NewTopicID(name Name, namespace Namespace) TopicID {
	return TopicID{
		name:      name,
		namespace: namespace,
	}
}

// ID returns a string identifier which references a GCP PubSub topic
func (t *TopicID) ID() string {
	if t.namespace == "" {
		return string(t.name)
	}
	return string(t.namespace) + "-" + string(t.name)
}

// Namespace returns the namespace of the TopicID, can be empty
func (t *TopicID) Namespace() Namespace {
	return t.namespace
}

type TopicService struct {
	Topic
	TopicCreator
}

func NewTopicService(c Client, topicID TopicID) *TopicService {
	t := c.Topic(topicID.ID())
	return &TopicService{
		Topic:        t,
		TopicCreator: c,
	}
}

// EnsureExists creates a topic without failing if it already exists.
func (s *TopicService) EnsureExists(ctx context.Context) error {
	ok, err := s.Exists(ctx)
	if err != nil {
		return errors.WithMessage(err, "failed to check if topic exists")
	}
	if ok {
		return nil
	}

	_, err = s.CreateTopic(ctx, s.ID())
	if err != nil {
		s, ok := status.FromError(err)
		if !ok || s.Code() != codes.AlreadyExists {
			return errors.WithMessage(err, "failed to create topic")
		}
	}
	return nil
}
