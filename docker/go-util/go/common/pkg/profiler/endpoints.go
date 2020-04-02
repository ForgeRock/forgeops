package profiler

import (
	"fmt"
	"net/http"
	"net/http/pprof"
	"time"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/httputil"

	"github.com/gin-gonic/gin"
)

// Endpoints configuration.
type Endpoints struct {
}

// NewHTTPRouter creates & runs an http router in the background
// with registered endpoints for projects that do not create
// an http router themselves
func NewHTTPRouter(sl httputil.ShutdownLifecycle, port int, shutdownDuration time.Duration) {
	if port == 0 {
		port = 8080
	}
	router := gin.Default()
	RegisterEndpoints(router)
	bindAddress := fmt.Sprintf(":%d", port)
	go httputil.GracefulRun(sl, router, bindAddress, shutdownDuration)
}

// RegisterEndpoints registers router endpoints for pprof profiler.
func RegisterEndpoints(e *gin.Engine) {
	ep := &Endpoints{}
	r := e.Group("/pprof")
	{
		r.GET("/", ep.ginHandler(pprof.Index))
		r.GET("/heap", ep.ginHandler(pprof.Handler("heap").ServeHTTP))
		r.GET("/allocs", ep.ginHandler(pprof.Handler("allocs").ServeHTTP))
		r.GET("/goroutine", ep.ginHandler(pprof.Handler("goroutine").ServeHTTP))
		r.GET("/block", ep.ginHandler(pprof.Handler("block").ServeHTTP))
		r.GET("/threadcreate", ep.ginHandler(pprof.Handler("threadcreate").ServeHTTP))
		r.GET("/cmdline", ep.ginHandler(pprof.Cmdline))
		r.GET("/profile", ep.ginHandler(pprof.Profile))
		r.GET("/symbol", ep.ginHandler(pprof.Symbol))
		r.GET("/trace", ep.ginHandler(pprof.Trace))
		r.GET("/mutex", ep.ginHandler(pprof.Handler("mutex").ServeHTTP))
	}
}

func (ep *Endpoints) ginHandler(handler http.HandlerFunc) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		handler(ctx.Writer, ctx.Request)
	}
}
