package httputil

import (
	"bytes"
	"io"
	"io/ioutil"
	"net/http"

	"github.com/xeipuuv/gojsonschema"
)

// SchemaValidator validation helper.
type SchemaValidator struct {
	schemaLoader gojsonschema.JSONLoader
	maxJSONBytes int64
}

// NewSchemaValidator initializes the SchemaValidator, given a JSON Schema v4 string and an upper-limit
// on the number of bytes in the JSON object in binary/string form, which is used to prevent HTTP flood
// attacks.
func NewSchemaValidator(schema string, maxJSONBytes int64) *SchemaValidator {
	return &SchemaValidator{
		schemaLoader: gojsonschema.NewStringLoader(schema),
		maxJSONBytes: maxJSONBytes,
	}
}

// Validate performs JSON Schema validation on the given HTTP request's payload.
func (v SchemaValidator) Validate(request *http.Request) (*gojsonschema.Result, error) {
	buf, err := ioutil.ReadAll(io.LimitReader(request.Body, v.maxJSONBytes))
	if err != nil {
		return nil, err
	}

	requestJSONLoader := gojsonschema.NewBytesLoader(buf)
	result, err := gojsonschema.Validate(v.schemaLoader, requestJSONLoader)
	if err == nil && result.Valid() {
		// replace the spent request body buffer, so that bind will work
		request.Body = ioutil.NopCloser(bytes.NewBuffer(buf))
	}
	return result, err
}
