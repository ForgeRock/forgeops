package messaging

import (
	"context"
	"sync"

	"cloud.google.com/go/pubsub"
)

// CallbackFunc is the required function signiture for gcloud pubsub callback handling.
type CallbackFunc func(ctx context.Context, msg *pubsub.Message)

// Exister interfaces things which can exist, or not
// Example: pubsub.Topic, pubsub.Subscription
type Exister interface {
	Exists(context.Context) (bool, error)
}

// Publisher provides the ability to publish a pubsub message.
// Example: provided by: pubsub.Topic
type Publisher interface {
	Publish(ctx context.Context, msg *pubsub.Message) *pubsub.PublishResult
}

// IDer returns the id as a string
// Example: pubsub.Subscription, pubsub.Topic
type IDer interface {
	ID() string
}

// Receiver receieves gcloud pubsub messages
// Nominally Provided By: pubsub.Subscription in the gcloud pubsub sdk
type Receiver interface {
	Receive(context.Context, func(context.Context, *pubsub.Message)) error
}

// TopicGetter returns a gcloud pubsub.Topic with the given id
// Example: pubsub.Client
type TopicGetter interface {
	Topic(id string) *pubsub.Topic
}

// SubscriptionGetter returns a gcloud pubsub.Subscription with the given id
// Example: pubsub.Client
type SubscriptionGetter interface {
	Subscription(string) *pubsub.Subscription
}

// SubscriptionCreator creates a gcloud pubsub.Subscription
// Example: pubsub.Client
type SubscriptionCreator interface {
	CreateSubscription(context.Context, string, pubsub.SubscriptionConfig) (*pubsub.Subscription, error)
}

// TopicCreator creates a gcloud pubsub.Subscription
// Example: pubsub.Client
type TopicCreator interface {
	CreateTopic(context.Context, string) (*pubsub.Topic, error)
}

// ExistenceEnsurer creates related resources if they don't already exist
// Example: TopicService
type ExistenceEnsurer interface {
	EnsureExists(context.Context) error
}

// Waits for a pubsub publish action to be completed and returns the result components
// Example: messageResultWaiter
type PublishResultWaiter interface {
	WaitForResult(context.Context, *pubsub.PublishResult) (messageID string, err error)
}

// BlockingPublisher publishes messages to gcloud pubsub topics and blocks until the operation completes
// Example: PublishService
type BlockingPublisher interface {
	Publish(context.Context, interface{}) (string, error)
}

// Closer closes resources
// Example: pubsub.Client
type Closer interface {
	Close() error
}

// -------------------------------

// Name uniquely identifies a topic or subscription within a namespace
type Name string

// Namespace groups a set of Name
type Namespace string

// TopicID and SubscriptionID can be namespaced. This is the value to use if no namespace is required.
const NoNamespace Namespace = ""

// Topic provides an interface for the gcloud pubsub.Topic struct
type Topic interface {
	Exister
	Publisher
	IDer
	Stop()
}

// Client provides an interface for the gcloud pubsub.Client struct
type Client interface {
	Closer
	TopicGetter
	TopicCreator
	SubscriptionGetter
	SubscriptionCreator
}

// Subscription provides an interface for the methods we're using from pubsub.Subscription
type Subscription interface {
	Exister
	Receiver
	IDer
}

// MessageServicer allows us to abstract the ack and nack methods from a pubsub.Message struct
type MessageServicer interface {
	Ack(*pubsub.Message)
	Nack(*pubsub.Message)
}

// MessageHandler would generally contain the logic for what to do with the contents of a message
type MessageHandler interface {
	HandleMessage(ctx context.Context, msg *pubsub.Message) error
}

// CallbackHandler is the top level handler for pubsub.Messages when they are received from a subscription
// THis is what is passed to the pubsub.Subscription{}.Receive method
type CallbackHandler interface {
	Callback(ctx context.Context, msg *pubsub.Message)
}

// Handler is a service that provides provides the logic for handling pubsub.messages from a subscription.
type Handler interface {
	Closer
	MessageHandler
}

// MessageHandlerFunc defines the signature for pubsub callback functions
// (functions passed to the pubsub.Subscription.ReceiveMessages).
type MessageHandlerFunc func(ctx context.Context, msg *pubsub.Message)

// WrappedMessageHandlerWrapper defines the signature for pubsub callback functions
// that are wrapped by a MessageHandlerFunc
type WrappedMessageHandlerFunc func(ctx context.Context, msg *pubsub.Message) error

// PublisherService provides an interface for the PublisherService struct
type PublisherServicer interface {
	BlockingPublisher
}

// TopicServicer provides an interface for the TopicService struct
type TopicServicer interface {
	Publisher
	ExistenceEnsurer
}

// SubscriptionServicer provides an interface for the SubscriptionService struct
type SubscriptionServicer interface {
	ReceiveMessages(context.Context, *sync.WaitGroup, chan error)
}

// SubscriptionRegisterer creates and stores SubscriptionServices
type SubscriptionRegisterer interface {
	Register(*pubsub.Client, TopicID, SubscriptionID, MessageHandlerFunc) *SubscriptionService
}

// SubscriptionServicesGetter returns the SubscriptionService objects registered with a SubscriptionRegistry
type SubscriptionServicesGetter interface {
	SubscriptionServices() []*SubscriptionService
}

// provides an interface for SubscriptionRegistry
type SubscriptionRegistryFace interface {
	SubscriptionRegisterer
	SubscriptionServicesGetter
}
