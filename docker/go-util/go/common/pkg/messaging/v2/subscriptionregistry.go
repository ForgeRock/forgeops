package messaging

import (
	"context"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
)

const DefaultAckDeadline = 10 * time.Minute

// SubscriptionRegistry is a fancy way of creating and storing a collection of SubscriptionServices
type SubscriptionRegistry struct {
	subscriptionServices []*SubscriptionService
	ackDeadline          time.Duration
	client               Client
	mutex                *sync.Mutex
}

func NewSubscriptionRegistry(client Client, ackDeadline time.Duration) *SubscriptionRegistry {
	if ackDeadline == 0 {
		ackDeadline = DefaultAckDeadline
	}
	return &SubscriptionRegistry{
		subscriptionServices: []*SubscriptionService{},
		ackDeadline:          ackDeadline,
		client:               client,
		mutex:                &sync.Mutex{},
	}
}

// SubscriptionServices returns the subscription services stored in the registry
func (r *SubscriptionRegistry) SubscriptionServices() []*SubscriptionService {
	return r.subscriptionServices
}

// Register sets up a SubscriptionService consuming messages from `subscriptionID` (from `topicID`) using `handler`
// Note: Multiple handlers can be registered for a given `topicID`
func (r *SubscriptionRegistry) Register(
	topicID TopicID,
	subscriptionID SubscriptionID,
	handler MessageHandlerFunc,
) *SubscriptionService {

	newSubSvc := NewSubscriptionService(r.client, topicID, subscriptionID, handler, r.ackDeadline)
	r.mutex.Lock()
	r.subscriptionServices = append(r.subscriptionServices, newSubSvc)
	r.mutex.Unlock()
	return newSubSvc
}

func (r *SubscriptionRegistry) Add(s *SubscriptionService) {
	r.mutex.Lock()
	r.subscriptionServices = append(r.subscriptionServices, s)
	r.mutex.Unlock()
}

// StartAllSubscriptionReceivers starts receiving messages with all subscriptions in the given registry.
// This will block until they're done receiving.
func (r *SubscriptionRegistry) StartAllAsyncWithGracefulShutdown(sl ShutdownLifecycle, ctx context.Context) {
	errChan := make(chan error)
	wg := &sync.WaitGroup{}
	for _, s := range r.SubscriptionServices() {
		log := logrus.WithFields(logrus.Fields{
			"func":           "ensureReady",
			"topicID":        s.topicID,
			"subscriptionID": s.subscriptionID,
		})
		log.Debug("Starting subscription")
		sl.Register(s.topicID.ID())
		wg.Add(1)
		go func(s *SubscriptionService) {
			defer sl.Done(s.topicID.ID())
			s.ReceiveMessages(WithShutdown(sl, ctx), wg, errChan)
			log.Debug("Subscription ended")
		}(s)
	}
	sl.Register("subscription-registry-errors")
	go func() {
		defer sl.Done("subscription-registry-errors")
		if err := blockWhileReceiving(wg, errChan, true); err != nil {
			logrus.WithError(err).Fatal("message handling failure")
		}
	}()
}

// blocks while any of the receivers are still running.
func blockWhileReceiving(wg *sync.WaitGroup, errChan chan error, stopOnAnyErr bool) error {
	log := logrus.WithFields(logrus.Fields{
		"pkg": "messaging",
		"svc": "SubscriptionRegistry",
	})
	waitChan := make(chan struct{})
	// this goroutine will close the waitChan and exit when the wait group is completed
	go func() {
		defer close(waitChan)
		wg.Wait()
	}()

	return logErrUntilDone(errChan, waitChan, log, stopOnAnyErr)
}

// log any errors that come through the errChan. returns when waitChan is closed.
func logErrUntilDone(errChan chan error, waitChan chan struct{}, log *logrus.Entry, stopOnAnyErr bool) error {
	// log errors as the come through the errChan, or exit when the waitgroup is completed
	for {
		receiveErr := doneOrErr(errChan, waitChan)
		if receiveErr == nil {
			break
		}
		// either return the error or log it
		if stopOnAnyErr {
			return receiveErr
		}
		log.WithError(receiveErr).Error("message handler failure")
	}
	return nil
}

// doneOrErr returns an error from errChan or nil if the waitChan is closed first.
func doneOrErr(errChan chan error, waitChan chan struct{}) error {
	select {
	case err := <-errChan:
		return err
	case <-waitChan:
		return nil
	}
}
