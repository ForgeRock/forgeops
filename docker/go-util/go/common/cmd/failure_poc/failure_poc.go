package main

import (
	"context"
	"sync"
	"time"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/messaging/v2"

	"cloud.google.com/go/pubsub"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
)

// TODO: Brainstorm potential problems, confirm them
// TODO: scaled testing: new card?
// - what happens if you just slam it with 10,000 requests, see if it operates as expected.
//   - verify nothing got lost
//   - verify nothing got duped
//   - verify for: intermittent failures, never-work, work right away
// - does the maxSleep actually accomplish what is expecting

// TODO: Document all the things very much well yes

func main() {
	logrus.SetFormatter(&logrus.JSONFormatter{})
	logrus.SetLevel(logrus.DebugLevel)
	log := logrus.WithField("pkg", "test")
	topicID := messaging.NewTopicID("test", messaging.NoNamespace)

	ctx := context.Background()
	c, err := pubsub.NewClient(ctx, "blah")
	if err != nil {
		log.WithError(err).Error()
	}

	fsc := messaging.FailureRetryBackOffConfig{
		MaxAttempts:         2,
		DeadLetterPublisher: messaging.NewPublishServiceSharedClient(c, messaging.NewTopicID("dlq", messaging.NoNamespace)),
		RePublisher:         messaging.NewPublishServiceSharedClient(c, topicID),
		BackOffDelayRatio:   2,
		BackOffDelayInit:    3000 * time.Millisecond,
		MaxSleep:            5 * time.Second,
		MaxDelay:            2000 * time.Millisecond,
	}
	fs, err := messaging.NewFailureRetryBackOff(fsc)
	if err != nil {
		log.WithError(err).Error("failed to create backoff strategy")
	}
	log.Debug("Created Failure Retry Backoff Strategy", fs)

	var previousProcess time.Time
	handler := func(ctx context.Context, msg *pubsub.Message) error {
		// track some stuff for testing.
		now := time.Now()
		log := log.WithFields(logrus.Fields{
			"ID":      msg.ID,
			"func":    "handler",
			"IDOrig":  msg.Attributes[string(messaging.AttrOriginalID)],
			"Attempt": msg.Attributes[string(messaging.AttrAttempts)],
		})
		if !previousProcess.IsZero() {
			sincePrev := now.Sub(previousProcess)
			log.Info("Since previous attempt: " + sincePrev.String())
		} else {
			log.Info("Initial Attempt")
		}
		previousProcess = now

		//return nil

		// trigger failure strategy
		return errors.New("somethin went wrong....")
	}

	subCfg := messaging.SubscriptionServiceConfig{
		Client:         c,
		TopicID:        topicID,
		SubscriptionID: messaging.NewSubscriptionID("test-new", messaging.NoNamespace),
		Options: messaging.SubscriptionServiceOptions{
			AckDeadline: 10 * time.Minute,
			ReceiveSettings: &pubsub.ReceiveSettings{
				MaxExtension:  -1,
				NumGoroutines: 10,
			},
			FailureStrategy: fs,
			WrappedHandler:  handler,
		},
	}
	sub, err := messaging.NewSubscriptionServiceFromConfig(subCfg)
	if err != nil {
		log.WithError(err).Info("failed to create new sub service")
	}
	wg := &sync.WaitGroup{}
	wg.Add(1)
	errChan := make(chan error)
	go sub.ReceiveMessages(ctx, wg, errChan)

	// Sleep to give it time to set up the subscription before publishing.
	time.Sleep(2 * time.Second)

	go func() {
		ps := messaging.NewPublishServiceSharedClient(c, messaging.NewTopicID("test", messaging.NoNamespace))
		id, err := ps.Publish(ctx, "yo")
		if err != nil {
			log.WithError(err).Error()
		}
		log.WithField("ID", id).Info("Published message")
	}()

	err = <-errChan
	log.Error(err)

	wg.Wait()
}
