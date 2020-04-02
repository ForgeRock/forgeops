package rpchttp

import (
	"time"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/httputil"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/rpc"
	"github.com/gin-gonic/gin"
	"github.com/osamingo/jsonrpc"
)

type Endpoints struct {
	methodRepo *jsonrpc.MethodRepository
	timeout    time.Duration
}

func NewEndpoints(services []rpc.Servicer, timeout time.Duration) *Endpoints {
	return &Endpoints{
		methodRepo: NewMethodRepo(services),
		timeout:    timeout,
	}
}

func NewMethodRepo(services []rpc.Servicer) *jsonrpc.MethodRepository {
	methodRepo := jsonrpc.NewMethodRepository()

	for _, s := range services {
		for _, h := range s.Handlers() {
			_ = methodRepo.RegisterMethod(s.MethodName(h), h, h.Params(), h.Result())
		}
	}
	return methodRepo
}

func RegisterEndpoints(router *gin.Engine, services []rpc.Servicer, timeout time.Duration) {
	ep := NewEndpoints(services, timeout)

	v1 := router.Group("/")
	{
		v1.POST("v1/rpc", httputil.WithContextHelper(ep.Post))
		v1.POST("/rpc", httputil.WithContextHelper(ep.Post))
	}
}
