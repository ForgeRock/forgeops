package pubsubclient

import (
	"context"

	"cloud.google.com/go/pubsub"
)

// PubSubber is a pub/sub client interface.
// See https://godoc.org/cloud.google.com/go/pubsub#Client
type PubSubber interface {
	// Close https://godoc.org/cloud.google.com/go/pubsub#Client.Close
	Close() error

	// CreateSubscription https://godoc.org/cloud.google.com/go/pubsub#Client.CreateSubscription
	CreateSubscription(ctx context.Context, id string, cfg pubsub.SubscriptionConfig) (Subscriptioner, error)

	// CreateTopic https://godoc.org/cloud.google.com/go/pubsub#Client.CreateTopic
	CreateTopic(ctx context.Context, id string) (Topicer, error)

	// Subscription https://godoc.org/cloud.google.com/go/pubsub#Client.Subscription
	Subscription(id string) Subscriptioner

	// Topic https://godoc.org/cloud.google.com/go/pubsub#Client.Topic
	Topic(id string) Topicer
}

// Topicer is a pub/sub topic interface.
// See https://godoc.org/cloud.google.com/go/pubsub#Topic
type Topicer interface {
	// Delete https://godoc.org/cloud.google.com/go/pubsub#Topic.Delete
	Delete(ctx context.Context) error

	// Exists https://godoc.org/cloud.google.com/go/pubsub#Topic.Exists
	Exists(ctx context.Context) (bool, error)

	// ID https://godoc.org/cloud.google.com/go/pubsub#Topic.ID
	ID() string

	// ID https://godoc.org/cloud.google.com/go/pubsub#Topic.Publish
	Publish(ctx context.Context, msg Messager) PublishResulter

	// Stop https://godoc.org/cloud.google.com/go/pubsub#Topic.Stop
	Stop()

	// String https://godoc.org/cloud.google.com/go/pubsub#Topic.String
	String() string
}

// PublishResulter is pub/sub publish-result interface.
// See https://godoc.org/cloud.google.com/go/pubsub#PublishResult
type PublishResulter interface {
	// Get https://godoc.org/cloud.google.com/go/pubsub#PublishResult.Get
	Get(ctx context.Context) (serverID string, err error)
}

// Subscriptioner is a pub/sub subscription interface.
// See https://godoc.org/cloud.google.com/go/pubsub#Subscription
type Subscriptioner interface {
	// Exists https://godoc.org/cloud.google.com/go/pubsub#Subscription.Exists
	Exists(ctx context.Context) (bool, error)

	// Receive https://godoc.org/cloud.google.com/go/pubsub#Subscription.Receive
	Receive(ctx context.Context, f func(context.Context, Messager)) error

	// String https://godoc.org/cloud.google.com/go/pubsub#Subscription.String
	String() string
}

// Messager is a pub/sub message interface.
// See https://godoc.org/cloud.google.com/go/pubsub#Message
type Messager interface {
	// Ack https://godoc.org/cloud.google.com/go/pubsub#Message.Ack
	Ack()

	// Nack https://godoc.org/cloud.google.com/go/pubsub#Message.Nack
	Nack()
}

// MessagerWithData extends Messager to make it possible to more fully mock pubsub.Message.
type MessagerWithData interface {
	Messager

	// Data function does not exist on pubsub.Message, but simulates access to the
	// pubsub.Message.Data field, for testing purposes.
	Data() []byte
}
