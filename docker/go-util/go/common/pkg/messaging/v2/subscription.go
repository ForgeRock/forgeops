package messaging

import (
	"context"
	"reflect"
	"sync"
	"time"

	"cloud.google.com/go/pubsub"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// SubscriptionID defines a namespaced reference to a GCP PubSub subscription
type SubscriptionID struct {
	name      Name
	namespace Namespace
}

// NewSubscriptionID creates a new SubscriptionID
// Use the NoNamespace const if name-spacing is not required
func NewSubscriptionID(name Name, namespace Namespace) SubscriptionID {
	return SubscriptionID{
		name:      name,
		namespace: namespace,
	}
}

// ID returns a string identifier which references a GCP PubSub Subscription
func (s *SubscriptionID) ID() string {
	if s.namespace == "" {
		return string(s.name)
	}
	return string(s.namespace) + "-" + string(s.name)
}

type SubscriptionService struct {
	client          Client
	topicID         TopicID
	topicService    TopicServicer
	subscriptionID  SubscriptionID
	subscription    Subscription
	handler         MessageHandlerFunc
	ackDeadline     time.Duration
	log             *logrus.Entry
	failureStrategy FailureStrategy
}

// SubscriptionServiceConfig includes all of the parameters to configure a SubscriptionService
type SubscriptionServiceConfig struct {
	Client         Client
	TopicID        TopicID
	SubscriptionID SubscriptionID
	Handler        MessageHandlerFunc
	Options        SubscriptionServiceOptions
}

// SubscriptionServiceOptions are optional parameters for a SubscriptionService initialization.
// Defaults will be used if any or all are not specified
type SubscriptionServiceOptions struct {
	// AckDeadline is the duration (when added to ReceiveSettings) that the pubsub service will wait
	// to redeliver a message if it is not Acked.
	// Note: If you want an AckDeadline more than 10 minutes, use ReceiveSettings.MaxExtension
	AckDeadline time.Duration
	// MessageService is used to ack and nack messages.
	// Recommended to use default (leave unassigned)
	MessageService MessageServicer
	// FailureStrategy determines what is done with a message if an error occurs during processing.
	FailureStrategy FailureStrategy
	// WrappedHandler is a pubsub handler that returns an error.
	// Since the pubsub Receive method has a different signature, this can only be used
	// with a failure strategy, which will wrap it in a method with the correct signature.
	WrappedHandler WrappedMessageHandlerFunc
	// ReceiveSettings provide additional options for configuring the underlying pubsub subscription.
	ReceiveSettings *pubsub.ReceiveSettings
}

// DefaultSubscriptionServiceOpts specifies default values for some SubscriptionServiceOptions
var DefaultSubscriptionServiceOpts = SubscriptionServiceOptions{
	// AckDeadline default of 0 means that the "real" value
	// (ackDeadline + maxExtension) is just equal to ReceiveSettings.MaxExtension
	AckDeadline:     0,
	ReceiveSettings: &DefaultReceiveSettings,
	MessageService:  &MessageService{},
	FailureStrategy: NewFailureDefault(),
}

// DefaultReceiveSettings specifies default values for ReceiveSettings
// used in place of the pubsub libraries default ReceiveSettings.
// TODO: Are these reasonable defaults for our use?
var DefaultReceiveSettings = pubsub.ReceiveSettings{
	MaxExtension:           20 * time.Minute,
	MaxOutstandingMessages: pubsub.DefaultReceiveSettings.MaxOutstandingMessages,
	MaxOutstandingBytes:    pubsub.DefaultReceiveSettings.MaxOutstandingBytes,
	NumGoroutines:          4,
}

// SubscriptionServiceOption provides an interface for passing in parameters in SubscriptionServiceOptions to the
// constructor one at a time.
type SubscriptionServiceOption interface {
	Apply(c *SubscriptionServiceConfig)
}

// OptAckDeadline is the option format of the AckDeadline parameter
type OptAckDeadline time.Duration

func (o OptAckDeadline) Apply(c *SubscriptionServiceConfig) {
	c.Options.AckDeadline = time.Duration(o)
}

// OptMessageService is the option format of the MessageService parameter
type OptMessageService struct {
	*MessageService
}

func (m *OptMessageService) Apply(c *SubscriptionServiceConfig) {
	c.Options.MessageService = m.MessageService
}

// OptFailureStrategy is the option format of the FailureStrategy parameter
type OptFailureStrategy struct {
	FailureStrategy
}

func (o OptFailureStrategy) Apply(c *SubscriptionServiceConfig) {
	c.Options.FailureStrategy = o.FailureStrategy
}

// OptReceiveSettings is the option format of the ReceiveSettings parameter
type OptReceiveSettings struct {
	pubsub.ReceiveSettings
}

func (o OptReceiveSettings) Apply(c *SubscriptionServiceConfig) {
	c.Options.ReceiveSettings = &o.ReceiveSettings
}

// OptWrappedHandler is the option format of the WrappedHandler parameter
type OptWrappedHandler WrappedMessageHandlerFunc

func (o OptWrappedHandler) Apply(c *SubscriptionServiceConfig) {
	c.Options.WrappedHandler = WrappedMessageHandlerFunc(o)
}

func applyDefaults(c SubscriptionServiceConfig, opts ...SubscriptionServiceOption) SubscriptionServiceConfig {

	// Apply defaults for any missing options.
	if c.Options.AckDeadline == 0 {
		c.Options.AckDeadline = DefaultSubscriptionServiceOpts.AckDeadline
	}
	if c.Options.MessageService == nil {
		c.Options.MessageService = DefaultSubscriptionServiceOpts.MessageService
	}
	if c.Options.FailureStrategy == nil {
		c.Options.FailureStrategy = DefaultSubscriptionServiceOpts.FailureStrategy
	}
	// To be able to take all default ReceiveSettings or override individual ReceiveSettings,
	// we need to check each field for 0 and set defaults.
	if c.Options.ReceiveSettings == nil {
		c.Options.ReceiveSettings = DefaultSubscriptionServiceOpts.ReceiveSettings
	}
	if c.Options.ReceiveSettings.MaxOutstandingBytes == 0 {
		c.Options.ReceiveSettings.MaxOutstandingBytes = DefaultReceiveSettings.MaxOutstandingBytes
	}
	if c.Options.ReceiveSettings.MaxOutstandingMessages == 0 {
		c.Options.ReceiveSettings.MaxOutstandingMessages = DefaultReceiveSettings.MaxOutstandingMessages
	}
	if c.Options.ReceiveSettings.NumGoroutines == 0 {
		c.Options.ReceiveSettings.NumGoroutines = DefaultReceiveSettings.NumGoroutines
	}
	if c.Options.ReceiveSettings.MaxExtension == 0 {
		c.Options.ReceiveSettings.MaxExtension = DefaultReceiveSettings.MaxExtension
	}

	return c
}

var ErrInvalidHandlerParameterCombination = errors.New("must pass in a WrappedHandler and not Handler if specifying a failure strategy")

// NewSubscriptionServiceFromConfig creates a new *SubscriptionService from the given SubscriptionServiceConfig and
// any SubscriptionServiceOptions passed in separately from the SubscriptionServiceConfig will serve as overrides.
func NewSubscriptionServiceFromConfig(c SubscriptionServiceConfig, opts ...SubscriptionServiceOption) (*SubscriptionService, error) {
	// Update config with any passed in options
	for _, o := range opts {
		o.Apply(&c)
	}

	// If a failure strategy is specified, they must use a Wrapped Handler, not a Handler
	// If both Handler and WrappedHandler are specified, it's not going to work however the user thinks it will.
	// If Handler is nil, both FailureStrategy and WrappedHandler can be specified (or not) independently.
	if c.Handler != nil && (c.Options.FailureStrategy != nil || c.Options.WrappedHandler != nil) {
		return nil, ErrInvalidHandlerParameterCombination
	}

	c = applyDefaults(c, opts...)

	// If a Handler is specified, assume that the handler is dealing with failures as needed and
	// no FailureStrategy is necessary.
	handler := c.Handler
	// If a Handler is not specified (and we made it this far), we have to set up the failure strategy.
	if handler == nil {
		// Validate that failure strategy specified will work with the given config.
		if err := c.Options.FailureStrategy.ValidateForSubscriptionConfig(c); err != nil {
			return nil, errors.Wrap(err, "failure strategy invalid for given SubscriptionServiceConfig")
		}

		// Add these attributes to the message
		// so we can track exactly where the message is coming from a little more easily
		// This could be most useful in deciphering the dead letter queue, or debug logging.
		trackingAttrs := map[AttrKey]string{
			AttrTopicID:        c.TopicID.ID(),
			AttrSubscriptionID: c.SubscriptionID.ID(),
		}

		handler = c.Options.FailureStrategy.WrapHandler(c.Options.WrappedHandler, trackingAttrs)
	}

	// Set up Subscription
	subscription := c.Client.Subscription(c.SubscriptionID.ID())
	subscription.ReceiveSettings = *c.Options.ReceiveSettings

	return &SubscriptionService{
		client:         c.Client,
		topicID:        c.TopicID,
		topicService:   NewTopicService(c.Client, c.TopicID),
		subscriptionID: c.SubscriptionID,
		subscription:   subscription,
		handler:        handler,
		ackDeadline:    c.Options.AckDeadline,
		log: logrus.WithFields(logrus.Fields{
			"pkg":            "messaging",
			"svc":            "SubscriptionService",
			"subscriptionID": c.SubscriptionID,
			"topicID":        c.TopicID.ID(),
		}),
		failureStrategy: c.Options.FailureStrategy,
	}, nil
}

func NewSubscriptionService(
	client Client,
	topicID TopicID,
	subscriptionID SubscriptionID,
	handler MessageHandlerFunc,
	ackDeadline time.Duration,
	opts ...SubscriptionServiceOption,
) *SubscriptionService {

	// Let's keep it backward compatible
	opts = append(opts, OptAckDeadline(ackDeadline))

	sub, _ := NewSubscriptionServiceFromConfig(
		SubscriptionServiceConfig{
			Client:         client,
			TopicID:        topicID,
			SubscriptionID: subscriptionID,
			Handler:        handler,
		},
		opts...)

	return sub
}

// ReceiveMessages starts receiving messages from the configured subscription
// optional parameter `errChan` can be used to receive error messages resulting from running the receiver
func (s *SubscriptionService) ReceiveMessages(ctx context.Context, wg *sync.WaitGroup, errChan chan error) {
	defer func() {
		if wg != nil {
			wg.Done()
		}
	}()
	log := s.log.WithField("func", "ReceiveMessages")

	if err := s.ensureReady(ctx); err != nil {
		log.Error(reflect.TypeOf(err).String())
		log.WithError(err).Error("Could not ensure subscription is ready")
		if errChan != nil {
			errChan <- err
		}
		return
	}

	if err := s.subscription.Receive(ctx, s.handler); err != nil {
		log.WithError(err).Error("Could not receive messages")
		if errChan != nil {
			errChan <- err
		}
	}
}

// ensureReady ensures that the required pubsub resources are configured and available for receiving messages
func (s *SubscriptionService) ensureReady(ctx context.Context) error {

	if err := s.topicService.EnsureExists(ctx); err != nil {
		return err
	}

	exists, err := s.subscription.Exists(ctx)
	if err != nil {
		return err
	}
	if exists {
		s.log.WithFields(logrus.Fields{
			"func":           "ensureReady",
			"subscriptionID": s.subscriptionID,
		}).Debug("Subscription does not need creating")
		return nil
	}

	subscriptionConfig := pubsub.SubscriptionConfig{
		Topic:       s.client.Topic(s.topicID.ID()),
		AckDeadline: s.ackDeadline}
	if newSub, err := s.client.CreateSubscription(ctx, s.subscriptionID.ID(), subscriptionConfig); err != nil {
		s, ok := status.FromError(err)
		if !ok || s.Code() != codes.AlreadyExists {
			return err
		}
	} else {
		s.subscription = newSub
	}

	s.log.WithFields(logrus.Fields{
		"func":           "ensureReady",
		"subscriptionID": s.subscriptionID,
	}).Debug("Created subscription")

	return nil
}
