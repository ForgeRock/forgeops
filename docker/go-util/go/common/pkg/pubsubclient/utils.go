package pubsubclient

import (
	"context"
	"time"

	"cloud.google.com/go/pubsub"
	log "github.com/sirupsen/logrus"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// EnsureTopic creates a pub/sub topic if it does not already exist.
func EnsureTopic(name string, pubsubClient PubSubber) (Topicer, error) {
	topic := pubsubClient.Topic(name)
	_, err := pubsubClient.CreateTopic(context.Background(), topic.ID())
	if err != nil && status.Code(err) != codes.AlreadyExists {
		return nil, err
	}
	return topic, nil
}

// SubscribeToTopic subscribes to a pub/sub topic, and creates it first if necessary.
//
// Typically you would call this function as a goroutine, because it will block the caller.
// All errors are logged and FATAL when fatalError=true, so care should be taken only to
// call this function during application startup. For testing, set fatalError=false and
// the error will be returned.
func SubscribeToTopic(ctx context.Context, fatalError bool, ackDeadline time.Duration, subscriptionName string, pubsubClient PubSubber, topic Topicer, receiver func(context.Context, Messager)) error {
	var pubsubTopic *pubsub.Topic
	if adapter, ok := topic.(TopicAdapter); ok {
		// this block will execute when using the real pubsub client, and the pubsubTopic
		// will just be nil during unit tests, which is OK in this function
		pubsubTopic = adapter.Topic
	}
	subConfig := pubsub.SubscriptionConfig{
		Topic:       pubsubTopic,
		AckDeadline: ackDeadline,
	}
	_, err := pubsubClient.CreateSubscription(ctx, subscriptionName, subConfig)
	if err != nil && status.Code(err) != codes.AlreadyExists {
		if fatalError {
			log.Fatal(err)
		}
		return err
	}
	sub := pubsubClient.Subscription(subscriptionName)
	err = sub.Receive(ctx, receiver)
	if err != nil {
		if fatalError {
			log.Fatal(err)
		}
		return err
	}
	return nil
}
