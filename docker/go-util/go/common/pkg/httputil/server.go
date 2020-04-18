package httputil

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type ShutdownLifecycle interface {
	Done(string)
	Register(string)
	ShuttingDown() <-chan struct{}
	TriggerShutdown()
}

// Run a Gin router at the specified address, gracefully handling SIGTERM and SIGINT OS signals.
// See also https://gin-gonic.com/docs/examples/graceful-restart-or-stop/
func GracefulRun(sl ShutdownLifecycle, engine *gin.Engine, addr string, shutdownTimeout time.Duration) {

	srv := &http.Server{
		Addr:    addr,
		Handler: engine,
	}

	sl.Register("http-server")
	go func() {
		defer sl.Done("http-server")
		err := srv.ListenAndServe()
		log.Debug("HTTP server finished listening")
		if err != nil && err != http.ErrServerClosed {
			log.WithError(err).Error("Failure from http server")
			sl.TriggerShutdown()
		}
	}()

	sl.Register("http-server-shutdown")
	go func() {
		defer sl.Done("http-server-shutdown")
		<-sl.ShuttingDown()
		log.Debug("Shutdown - shutting down HTTP server")

		ctx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
		defer cancel()
		if err := srv.Shutdown(ctx); err != nil {
			log.WithError(err).Error("Error shutting down http server")
		}
		log.Debug("HTTP server shut down")
	}()
}
