package testutil

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"

	"github.com/gin-gonic/gin"
)

var (
	// IgnoreContext is used in place of nil for mock *gin.Context return arguments to make intent obvious
	IgnoredContext *gin.Context

	// NilError is used in place of nil for mock error return arguments to make intent obvious
	NilError error

	// AnyError is used to represent an error when it doesn't really matter which error for testing
	AnyError = errors.New("any error")
)

// NewGinTestContext creates a gin.Context for testing.
func NewGinTestContext() *gin.Context {
	recorder := httptest.NewRecorder()
	ginContext, _ := gin.CreateTestContext(recorder)
	return ginContext
}

// NewTestHttpRequest creates a new http.Request for testing purposes. Panics on errors.
func NewTestHttpRequest(method string, url string, body interface{}) *http.Request {
	if body == nil {
		body = new(bytes.Buffer)
	}

	jsonBody, err := json.Marshal(body)
	if err != nil {
		// Unit test code, panicking on errors to simplify use
		panic(err)
	}

	// Converting byte array to string this way requires a slice as input or so I've read.
	bodyString := string(jsonBody[:])
	request, err := http.NewRequest(method, url, strings.NewReader(bodyString))
	if err != nil {
		// Unit test code, panicking on errors to simplify use
		panic(err)
	}
	return request
}

// NewTestRequestContext create's a gin.Context with a http.Request populated and ready for testing.
// Argument 'body' can be nil
func NewTestRequestContext(method string, url string, body interface{}, ginParams ...gin.Param) *gin.Context {
	context := NewGinTestContext()
	context.Request = NewTestHttpRequest(method, url, body)
	context.Params = gin.Params(ginParams)
	return context
}
