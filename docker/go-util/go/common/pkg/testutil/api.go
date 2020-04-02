package testutil

import (
	"fmt"
	"testing"

	"github.com/buger/jsonparser"
	"github.com/stretchr/testify/assert"
)

//nolint:gosimple
// AssertJSONEqual asserts that a JSON byte array matches boolean, integer, and/or string fields in a map.
// When an unsupported map-value type is encountered, this function will assert a failure condition and return.
func AssertJSONEqual(t *testing.T, expectedMap map[string]interface{}, actualData []byte) {
	for k, expected := range expectedMap {
		switch expected.(type) {
		case bool:
			actual, _ := jsonparser.GetBoolean(actualData, k)
			assert.EqualValues(t, expected.(bool), actual)
		case int64:
			actual, _ := jsonparser.GetInt(actualData, k)
			assert.EqualValues(t, expected.(int64), actual)
		case string:
			actual, _ := jsonparser.GetString(actualData, k)
			assert.EqualValues(t, expected.(string), actual)
		default:
			assert.Fail(t, fmt.Sprintf("Unhandled type for key: %v", k))
			return
		}
	}
}
