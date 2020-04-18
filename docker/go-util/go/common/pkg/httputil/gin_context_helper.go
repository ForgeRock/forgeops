package httputil

import (
	"context"
	"io/ioutil"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
)

type HttpRequestContext struct{}

func (c *HttpRequestContext) AbortWithStatusJSON(context *gin.Context, code int, jsonObj interface{}) {
	context.AbortWithStatusJSON(code, jsonObj)
}

func (c *HttpRequestContext) GetHeader(context *gin.Context, key string) string {
	return context.GetHeader(key)
}

func (c *HttpRequestContext) Next(context *gin.Context) {
	context.Next()
}

func (c *HttpRequestContext) GetRequestURLPath(context *gin.Context) string {
	return context.Request.URL.Path
}

// ValidateAndBindRequestBody validates the request and binds the http request's JSON payload values onto the requestBody.
// This mutates requestBody.
func (c *HttpRequestContext) ValidateAndBindRequestBody(context *gin.Context, requestBody interface{}, validator EntitySchemaValidator) error {
	if err := c.ValidateRequest(validator, context.Request); err != nil {
		return err
	}

	if err := c.BindRequestBody(&requestBody, context.Request); err != nil {
		return err
	}

	return nil
}

func (c *HttpRequestContext) GetContext(context *gin.Context) context.Context {
	return context.Request.Context()
}

func (c *HttpRequestContext) GetParam(context *gin.Context, key string) string {
	return context.Param(key)
}

func (c *HttpRequestContext) GetParamInt64(context *gin.Context, key string) (int64, error) {
	if HasParam(key, context) {
		return strconv.ParseInt(context.Param(key), 10, 64)
	}

	return 0, nil
}

func (c *HttpRequestContext) GetQuery(context *gin.Context, key string) (string, bool) {
	return context.GetQuery(key)
}

func (c *HttpRequestContext) HasParam(context *gin.Context, key string) bool {
	return HasParam(key, context)
}

// ParseEntityID parses a string to find a number ID and if not tries to default to 'defaultID'
func (c *HttpRequestContext) ParseEntityID(context *gin.Context, idKey string, defaultID int64) (int64, error) {
	src := context.Param(idKey)

	return ParseEntityID(src, defaultID)
}

// BindRequestBody binds the http request's JSON payload values onto the requestBody.
// This mutates requestBody.
func (c *HttpRequestContext) BindRequestBody(requestBody interface{}, request *http.Request) error {

	// Bind simple strings
	if bound, ok := requestBody.(*string); ok {
		data, err := ioutil.ReadAll(request.Body)
		if err != nil {
			return err
		}

		*bound = string(data)
		return nil
	}

	// Bind JSON
	if err := binding.JSON.Bind(request, &requestBody); err != nil {
		log.Printf("Can not bind JSON payload: %s", err)
		return ErrUnexpectedJSONPayloadError
	}

	return nil
}

// ValidateRequest executes the 'validator' against the http request to make sure it is a valid JSON payload and
// returns custom error(s) if any
func (c *HttpRequestContext) ValidateRequest(validator EntitySchemaValidator, request *http.Request) MultiError {
	result, err := validator.Validate(request)
	if err != nil {
		log.Printf("Can not validate JSON payload: %s", err)
		return MultiError{ErrInvalidJSONPayload}
	}

	if !result.Valid() {
		// invalid JSON payload
		return ConvertToMultiError(result.Errors())
	}

	return nil
}
