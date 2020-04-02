package pubsubclient

import (
	"context"

	"cloud.google.com/go/pubsub"
	messaging "github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/messaging/v2"
	log "github.com/sirupsen/logrus"
)

// ClientAdapter wraps a Pub/Sub Client to expose the PubSubber interface.
type ClientAdapter struct {
	messaging.Client
}

// NewClientAdapter creates a new ClientAdapter.
func NewClientAdapter(client messaging.Client) ClientAdapter {
	return ClientAdapter{client}
}

// CreateSubscription creates a Subscriptioner.
func (a ClientAdapter) CreateSubscription(ctx context.Context, id string, cfg pubsub.SubscriptionConfig) (Subscriptioner, error) {
	subscription, err := a.Client.CreateSubscription(ctx, id, cfg)
	if err != nil {
		return nil, err
	}
	return SubscriptionAdapter{subscription}, nil
}

// Subscription gets a Subscriptioner by id.
func (a ClientAdapter) Subscription(id string) Subscriptioner {
	return SubscriptionAdapter{a.Client.Subscription(id)}
}

// CreateTopic creates a Topicer.
func (a ClientAdapter) CreateTopic(ctx context.Context, id string) (Topicer, error) {
	topic, err := a.Client.CreateTopic(ctx, id)
	return TopicAdapter{topic}, err
}

// Topic gets a Topicer.
func (a ClientAdapter) Topic(id string) Topicer {
	return TopicAdapter{a.Client.Topic(id)}
}

func (a ClientAdapter) Close() error {
	return a.Client.Close()
}

// SubscriptionAdapter wraps Pub/Sub Client subscription to expose the Subscriptioner interface.
type SubscriptionAdapter struct {
	*pubsub.Subscription
}

// Receive adapts a pubsub.Message to a Messager interface.
func (a SubscriptionAdapter) Receive(ctx context.Context, f func(context.Context, Messager)) error {
	adapter := func(c context.Context, m *pubsub.Message) {
		f(c, m)
	}
	log.Infof("Receiving from %s", a.ID())
	return a.Subscription.Receive(ctx, adapter)
}

// TopicAdapter wraps Pub/Sub Client topic to expose the Topicer interface.
type TopicAdapter struct {
	*pubsub.Topic
}

// Publish publishes a message and returns PublishResulter.
func (a TopicAdapter) Publish(ctx context.Context, msg Messager) PublishResulter {
	pubsubMsg, ok := msg.(*pubsub.Message)
	if !ok {
		log.Errorf("expected msg to be *pubsub.Message, but got: %#v", msg)
	}
	return PublishResulterAdapter{a.Topic.Publish(ctx, pubsubMsg)}
}

// PublishResulterAdapter wraps Pub/Sub Client publish-result to expose the PublishResulter interface.
type PublishResulterAdapter struct {
	*pubsub.PublishResult
}
