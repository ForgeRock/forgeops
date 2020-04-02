package testutil

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/stretchr/testify/require"
)

type closerNoOp struct{}

func (c *closerNoOp) Close() error {
	return nil
}

// MarshalHTTPResponse converts a JSON-annotated struct into a HTTP response. If jsonStruct is nil
// then the response has an empty JSON payload.
func MarshalHTTPResponse(t require.TestingT, statusCode int, jsonStruct interface{}) *http.Response {
	var responseBodyBytes []byte
	if jsonStruct != nil {
		b, err := json.Marshal(jsonStruct)
		if err != nil {
			require.FailNow(t, fmt.Sprintf("Unexpected error: %v", err))
		}
		responseBodyBytes = b
	}
	return &http.Response{
		StatusCode: statusCode,
		Body: struct {
			io.Reader
			io.Closer
		}{
			bytes.NewReader(responseBodyBytes),
			&closerNoOp{},
		},
	}
}

// BasicHTTPResponse converts a string into a HTTP response
func BasicHTTPResponse(t require.TestingT, statusCode int, body string) *http.Response {
	responseBodyBytes := []byte(body)
	return &http.Response{
		StatusCode: statusCode,
		Body: struct {
			io.Reader
			io.Closer
		}{
			bytes.NewReader(responseBodyBytes),
			&closerNoOp{},
		},
	}
}
