package messaging

import (
	"context"

	log "github.com/sirupsen/logrus"
)

type ShutdownLifecycle interface {
	Done(string)
	Register(string)
	ShuttingDown() <-chan struct{}
}

func WithShutdown(sl ShutdownLifecycle, parent context.Context) context.Context {
	ctx, cancel := context.WithCancel(parent)
	go func() {
		<-sl.ShuttingDown()
		log.Info("Shutdown - cancelling pubsub subscription")
		cancel()
	}()
	return ctx
}
