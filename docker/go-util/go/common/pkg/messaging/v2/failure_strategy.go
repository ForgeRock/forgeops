package messaging

// FailureStrategy provides a failure handling strategy for pubsub message processing.
// Example Functionality:
//  - insert a delay before Nacking a message
//  - insert additional logging or insert tracking information into a message
//  - implement a dead letter queue for messages that fail too often.
type FailureStrategy interface {
	// WrapHandler wraps the given handler function, allowing for manipulation of the message
	// prior to the handler and the ability to take appropriate action on any returned errors.
	WrapHandler(h WrappedMessageHandlerFunc, trackingAttributes map[AttrKey]string) MessageHandlerFunc
	// ValidateForSubscriptionConfig provides validation capabilities to ensure that a given FailureStrategy
	// will work with the SubscriptionService as configured.
	ValidateForSubscriptionConfig(cfg SubscriptionServiceConfig) error
}
