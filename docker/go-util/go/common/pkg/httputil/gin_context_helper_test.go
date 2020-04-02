package httputil

import (
	"errors"
	"io/ioutil"
	"net/http"
	"reflect"
	"strings"
	"testing"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/testutil"
	"github.com/gin-gonic/gin"
)

const (
	jobStatusMaxJSONBytes = 1000
)

func TestHttpRequestContext_GetParam(t *testing.T) {
	type args struct {
		c   *gin.Context
		key string
	}
	contextWithID := testutil.NewTestRequestContext(
		"GET",
		"/test",
		nil,
		gin.Param{Key: "id", Value: "100"})
	h := &HttpRequestContext{}
	tests := []struct {
		name string
		c    *HttpRequestContext
		args args
		want string
	}{
		{"successfully get param", h, args{c: contextWithID, key: "id"}, "100"},
		{"get non-param", h, args{c: contextWithID, key: "id1"}, ""},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := &HttpRequestContext{}
			if got := c.GetParam(tt.args.c, tt.args.key); got != tt.want {
				t.Errorf("HttpRequestContext.GetParam() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestHttpRequestContext_GetParamInt64(t *testing.T) {
	type args struct {
		context *gin.Context
		key     string
	}
	contextWithID := testutil.NewTestRequestContext(
		"GET",
		"/test",
		nil,
		gin.Param{Key: "id", Value: "100"})
	h := &HttpRequestContext{}
	tests := []struct {
		name    string
		c       *HttpRequestContext
		args    args
		want    int64
		wantErr bool
	}{
		{"successfully get param", h, args{context: contextWithID, key: "id"}, 100, false},
		{"get non-param should be zero?", h, args{context: contextWithID, key: "id1"}, 0, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := &HttpRequestContext{}
			got, err := c.GetParamInt64(tt.args.context, tt.args.key)
			if (err != nil) != tt.wantErr {
				t.Errorf("HttpRequestContext.GetParamInt64() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if got != tt.want {
				t.Errorf("HttpRequestContext.GetParamInt64() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestHttpRequestContext_GetQuery(t *testing.T) {
	type args struct {
		context *gin.Context
		key     string
	}
	contextWithID := testutil.NewTestRequestContext(
		"GET",
		"/test?a=1&b=c",
		nil,
		gin.Param{Key: "id", Value: "100"})
	h := &HttpRequestContext{}
	tests := []struct {
		name  string
		c     *HttpRequestContext
		args  args
		want  string
		want1 bool
	}{
		{"get url query", h, args{context: contextWithID, key: "a"}, "1", true},
		{"get url query second", h, args{context: contextWithID, key: "b"}, "c", true},
		{"get url query fail", h, args{context: contextWithID, key: "c"}, "", false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := &HttpRequestContext{}
			got, got1 := c.GetQuery(tt.args.context, tt.args.key)
			if got != tt.want {
				t.Errorf("HttpRequestContext.GetQuery() got = %v, want %v", got, tt.want)
			}
			if got1 != tt.want1 {
				t.Errorf("HttpRequestContext.GetQuery() got1 = %v, want %v", got1, tt.want1)
			}
		})
	}
}

func TestValidateRequest(t *testing.T) {
	type args struct {
		validator EntitySchemaValidator
		request   *http.Request
	}
	f, _ := ioutil.ReadFile("fixtures/job_status_schema.json")
	v := NewSchemaValidator(string(f[:]), jobStatusMaxJSONBytes)
	v1 := NewSchemaValidator(string(f[:]), 1)
	r1, _ := http.NewRequest("POST", "/", strings.NewReader(`{}`))
	r, _ := http.NewRequest("POST", "/", strings.NewReader(`{}`))
	rValid, _ := http.NewRequest("POST", "/", strings.NewReader(`{"type":"ab","value":"abc"}`))
	rInValid, _ := http.NewRequest("POST", "/", strings.NewReader(`{"type":"","value":"abc"}`))
	m := MultiError{errors.New("(root): type is required"), errors.New("(root): value is required")}
	mFailedValidation := MultiError{
		errors.New("type: String length must be greater than or equal to 1"),
		errors.New("type: Does not match pattern '^[a-zA-Z0-9_-]+$'")}
	tests := []struct {
		name string
		args args
		want MultiError
	}{
		{"not valid request", args{validator: v1, request: r1},
			MultiError{errors.New("invalid JSON payload")},
		},
		{"not valid json", args{validator: v, request: r}, m},
		{"valid json", args{validator: v, request: rValid}, nil},
		{"invalid json", args{validator: v, request: rInValid}, mFailedValidation},
	}

	helper := HttpRequestContext{}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := helper.ValidateRequest(tt.args.validator, tt.args.request); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("ValidateRequest() = %v, want %v", got, tt.want)
			}
		})
	}
}
