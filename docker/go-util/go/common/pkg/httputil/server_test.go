package httputil

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"sync"
	"testing"
	"time"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/testutil"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func TestGracefulShutdown(t *testing.T) {
	type args struct {
		engine          *gin.Engine
		requestReceived chan bool
		shutdownTimeout time.Duration
	}
	fastEngine, fastRequestReceived := engineWithPause(100 * time.Millisecond)
	slowEngine, slowRequestReceived := engineWithPause(2000 * time.Millisecond)
	tests := []struct {
		name           string
		args           args
		expectComplete bool
	}{
		{"awaits normal requests", args{fastEngine, fastRequestReceived, 2000 * time.Millisecond}, true},
		{"long requests killed", args{slowEngine, slowRequestReceived, 100 * time.Millisecond}, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			port, err := testutil.GetFreePort()
			if err != nil {
				t.Fatalf("Could not find free port: %s", err)
			}

			ctx, cancel := context.WithCancel(context.Background())
			trapper := &Trapper{ctx, cancel, &sync.WaitGroup{}}
			shutdownComplete := make(chan bool)
			go func() {
				t.Logf("[Server] Start graceful server on port %v", port)
				GracefulRun(trapper, tt.args.engine, ":"+strconv.Itoa(port), tt.args.shutdownTimeout)
				trapper.wg.Wait()
				t.Log("[Server] Graceful server Shutdown complete")
				shutdownComplete <- true
			}()

			hc := &http.Client{Timeout: 3 * time.Second}

			t.Logf("[Main] Check server is alive")
			checkAlive(t, hc, port)

			var serverDone bool
			var reqCompleted bool
			finished := make(chan struct{})
			go func() {
				defer close(finished)
				t.Logf("[Client] Send request")
				_, err := hc.Get(fmt.Sprintf("http://localhost:%d/", port))
				t.Logf("[Client] Request successful: %v", err == nil)
				if reqCompleted = err == nil; !serverDone && reqCompleted != tt.expectComplete {
					t.Errorf("[Client] Expected request to complete %t but was %t", tt.expectComplete, reqCompleted)
				}
				if err != nil {
					t.Logf("[Client] Error %s", err)
				}
			}()

			<-tt.args.requestReceived
			t.Log("[Main] Request received, shutdown the server")
			cancel()

			serverDone = <-shutdownComplete
			t.Log("[Main] Shutdown complete")

			if reqCompleted != tt.expectComplete {
				t.Errorf("[Main] Expected request to complete after shutdown %t but was %t", tt.expectComplete, reqCompleted)
			}

			<-finished
		})
	}
}

func checkAlive(t *testing.T, hc *http.Client, port int) {
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()
	ticker := time.NewTicker(10 * time.Millisecond)
	defer ticker.Stop()
	for {
		_, err := hc.Get(fmt.Sprintf("http://localhost:%d/ping", port))
		if err == nil {
			t.Log("Successful ping")
			return
		}
		t.Log("Failed ping")
		select {
		case <-ctx.Done():
			t.Fatal("Server failed to come alive")
		case <-ticker.C:
		}
	}
}

func engineWithPause(t time.Duration) (engine *gin.Engine, requestReceived chan bool) {
	engine = gin.New()
	requestReceived = make(chan bool)
	engine.GET("/", func(c *gin.Context) {
		log.Infof("Received request")
		requestReceived <- true
		ctx, cancel := context.WithTimeout(context.Background(), t)
		defer cancel()
		ticker := time.NewTicker(10 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				log.Infof("Completing request")
				c.Status(204)
				c.Done()
				return
			case <-ticker.C:
			}
		}
	})
	engine.GET("/ping", func(c *gin.Context) {
		log.Infof("ping")
		c.Status(204)
		c.Done()
	})
	return
}

type Trapper struct {
	ctx    context.Context
	cancel context.CancelFunc
	wg     *sync.WaitGroup
}

func (t Trapper) Done(_ string) {
	t.wg.Done()
}

func (t Trapper) Register(_ string) {
	t.wg.Add(1)
}

func (t Trapper) ShuttingDown() <-chan struct{} {
	return t.ctx.Done()
}

func (t Trapper) TriggerShutdown() {
	t.cancel()
}
