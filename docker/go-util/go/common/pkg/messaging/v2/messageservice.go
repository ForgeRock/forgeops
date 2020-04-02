package messaging

import (
	"cloud.google.com/go/pubsub"
)

// MessageService allows us to separate the functionality of a message from the content.
// This is mostly to facilitate testing w/ mocks
type MessageService struct{}

func (_ *MessageService) Ack(msg *pubsub.Message) {
	msg.Ack()
}

func (m *MessageService) Nack(msg *pubsub.Message) {
	msg.Nack()
}
