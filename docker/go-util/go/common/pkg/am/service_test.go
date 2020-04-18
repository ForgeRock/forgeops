package am

import (
	"bytes"
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/models/app"
)

func TestErrorResponse(t *testing.T) {
	resp := &ErrorResponse{}
	assert.NoError(t, json.Unmarshal([]byte("{\"code\":123,\"message\":\"an error\",\"reason\":\"for testing\"}"), resp))
	assert.Equal(t, int64(123), resp.Code)
	assert.Equal(t, "an error", resp.Message)
	assert.Equal(t, "for testing", resp.Reason)
	assert.Empty(t, resp.Detail)

	resp = &ErrorResponse{}
	assert.NoError(t, json.Unmarshal([]byte("{\"code\":123,\"message\":\"another error\",\"reason\":\"for testing\",\"detail\":{\"foo\":\"bar\"}}"), resp))
	assert.Equal(t, int64(123), resp.Code)
	assert.Equal(t, "another error", resp.Message)
	assert.Equal(t, "for testing", resp.Reason)
	assert.Equal(t, "bar", resp.Detail["foo"])
}

func TestService_UpdateOAuth2Client(t *testing.T) {
	rev := "xyz987"
	oc := &app.OAuth2Client{ID: "abc123", Rev: &rev}
	httpClient := &mockHttpClient{}
	service := &service{client: httpClient, cache: cacheTokenId{tokenId: "mytoken"}}
	httpClient.On("Do", mock.MatchedBy(func(req *http.Request) bool {
		body, _ := ioutil.ReadAll(req.Body)
		return strings.HasSuffix(req.URL.Path, "/abc123") &&
			req.Header.Get("if-match") == "xyz987" &&
			!strings.Contains(string(body), "_rev")
	})).Return(&http.Response{Body: emptyBody(), StatusCode: 200}, nil)
	assert.NoError(t, service.UpdateOAuth2Client(oc))
	assert.Nil(t, oc.Rev)
}

func emptyBody() io.ReadCloser {
	return ioutil.NopCloser(bytes.NewBuffer([]byte{}))
}

type mockHttpClient struct {
	mock.Mock
}

func (_m *mockHttpClient) Do(req *http.Request) (*http.Response, error) {
	ret := _m.Called(req)

	var r0 *http.Response
	if rf, ok := ret.Get(0).(func(*http.Request) *http.Response); ok {
		r0 = rf(req)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(*http.Response)
		}
	}

	var r1 error
	if rf, ok := ret.Get(1).(func(*http.Request) error); ok {
		r1 = rf(req)
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}
