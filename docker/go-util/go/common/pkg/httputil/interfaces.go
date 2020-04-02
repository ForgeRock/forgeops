package httputil

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
)

type GinContextHelper interface {
	AbortWithStatusJSON(context *gin.Context, code int, jsonObj interface{})
	GetContext(context *gin.Context) context.Context
	GetHeader(context *gin.Context, key string) string
	GetParam(context *gin.Context, key string) string
	GetParamInt64(context *gin.Context, key string) (int64, error)
	GetQuery(context *gin.Context, key string) (string, bool)
	GetRequestURLPath(context *gin.Context) string
	HasParam(context *gin.Context, key string) bool
	Next(context *gin.Context)
	ParseEntityID(context *gin.Context, idKey string, defaultID int64) (int64, error)
	ValidateAndBindRequestBody(*gin.Context, interface{}, EntitySchemaValidator) error
	BindRequestBody(requestBody interface{}, request *http.Request) error
	ValidateRequest(validator EntitySchemaValidator, request *http.Request) MultiError
}

// HTTPClienter interface for mocking the underlying HTTP client in tests.
type HTTPClienter interface {
	// Do executes a HTTP request and returns the response or an error.
	Do(req *http.Request) (resp *http.Response, err error)
}
