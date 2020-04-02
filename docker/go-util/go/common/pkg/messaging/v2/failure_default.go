package messaging

import (
	"context"
	"time"

	"cloud.google.com/go/pubsub"
)

// FailureDefault is intended to be the default failure strategy if no other strategy is specified.
// While it can be specified explicitly, it will be used automatically if none is specified.
type FailureDefault struct {
	msgService    MessageServicer
	delayDuration time.Duration
}

// NewFailureDefault constructs a new FailureDefault struct.
func NewFailureDefault() *FailureDefault {
	return &FailureDefault{
		msgService:    &MessageService{},
		delayDuration: 10 * time.Second,
	}
}

// WrapHandler (for FailureDefault) inserts some additional tracking attributes into the message and
// handles failure scenarios if the handler returns an error.
//
// The default strategy also inserts a sleep prior to nacking to prevent
// it from endless instant retries (for example, if a prerequisite service is down temporarily)
func (s FailureDefault) WrapHandler(h WrappedMessageHandlerFunc, trackingAttributes map[AttrKey]string) MessageHandlerFunc {
	return func(ctx context.Context, msg *pubsub.Message) {
		// Insert additional tracking attributes
		if msg.Attributes == nil {
			msg.Attributes = make(map[string]string)
		}
		for k, v := range trackingAttributes {
			msg.Attributes[string(k)] = v
		}
		// Handle message
		if err := h(ctx, msg); err != nil {
			time.Sleep(s.delayDuration)
			s.msgService.Nack(msg)
			return
		}
		s.msgService.Ack(msg)
	}
}

// ValidateForSubscriptionConfig does nothing for FailureDefault, since there are no special considerations
// for this failure strategy.
func (s FailureDefault) ValidateForSubscriptionConfig(cfg SubscriptionServiceConfig) error {
	// No special considerations
	return nil
}
