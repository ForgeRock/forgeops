package rpchttp

import (
	"net/http"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/httputil"
	"github.com/gin-gonic/gin"
	"github.com/osamingo/jsonrpc"
	log "github.com/sirupsen/logrus"
)

// failure is a convenience method to return the full signature for a failure response
func failure(statusCode uint, err error, responseBody *jsonrpc.Response) (*httputil.EndpointResponse, error) {
	return httputil.NewEndpointResponse(responseBody, statusCode), err
}

// success is a convenience method to return the full signature for a successful response
func success(responseBody *jsonrpc.Response) (*httputil.EndpointResponse, error) {
	return httputil.NewEndpointResponse(responseBody, http.StatusOK), nil
}
func successes(responseBody []*jsonrpc.Response) (*httputil.EndpointResponse, error) {
	return httputil.NewEndpointResponse(responseBody, http.StatusOK), nil
}

type ResponseBody struct {
	jsonrpc.Response
}

func (ep Endpoints) Post(
	ginContext *gin.Context,
	contextHelper httputil.GinContextHelper,
) (*httputil.EndpointResponse, error) {

	if ginContext.GetHeader("Content-Type") == "" {
		// Let's assume best intent if not indicated
		ginContext.Header("Content-Type", "application/json")
	}
	requests, isBatch, err := jsonrpc.ParseRequest(ginContext.Request)
	if err != nil {
		resp := &jsonrpc.Response{
			Error:   err,
			Version: jsonrpc.Version,
		}
		log.Errorf("Failure parsing request: err=%q", err)
		return failure(http.StatusInternalServerError, err, resp)
	}

	ctx, cancel := httputil.ContextWithTimeout(ginContext, ep.timeout)
	defer cancel()

	var responses []*jsonrpc.Response
	for _, req := range requests {
		resp := ep.methodRepo.InvokeMethod(ctx, req)
		logAndStripDetailedErrorStuff(resp)
		responses = append(responses, resp)
	}

	if !isBatch && len(responses) == 1 {
		return success(responses[0])
	}
	return successes(responses)
}

func logAndStripDetailedErrorStuff(res *jsonrpc.Response) {
	if res.Error != nil {
		errMap, ok := res.Error.Data.(map[string]error)
		if ok {
			log.Error(errMap["error"])
			res.Error.Data = nil
		}
	}
}
