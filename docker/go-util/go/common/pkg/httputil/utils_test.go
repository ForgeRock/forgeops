package httputil

import (
	"strconv"
	"testing"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/testutil"
	"github.com/gin-gonic/gin"
)

func TestHasParam(t *testing.T) {
	type args struct {
		key string
		c   *gin.Context
	}
	context := testutil.NewTestRequestContext(
		"GET",
		"/test",
		nil,
		gin.Param{Key: "id", Value: strconv.Itoa(10)})
	tests := []struct {
		name string
		args args
		want bool
	}{
		{"got param successful", args{key: "id", c: context}, true},
		{"got param unsuccessful", args{key: "id1", c: context}, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := HasParam(tt.args.key, tt.args.c); got != tt.want {
				t.Errorf("HasParam() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestIDParam(t *testing.T) {
	type args struct {
		ginContext *gin.Context
	}
	context := testutil.NewTestRequestContext(
		"GET",
		"/test",
		nil,
		gin.Param{Key: "id", Value: strconv.Itoa(10)})
	contextNoID := testutil.NewTestRequestContext(
		"GET",
		"/test",
		nil,
		gin.Param{})
	contextNegativeID := testutil.NewTestRequestContext(
		"GET",
		"/test",
		nil,
		gin.Param{Key: "id", Value: strconv.Itoa(-10)})
	tests := []struct {
		name    string
		args    args
		want    int64
		wantErr bool
	}{
		{"has id test", args{ginContext: context}, 10, false},
		{"has no id test", args{ginContext: contextNoID}, 0, true},
		{"has a negative id test", args{ginContext: contextNegativeID}, 0, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := IDParam(tt.args.ginContext)
			if (err != nil) != tt.wantErr {
				t.Errorf("IDParam() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if got != tt.want {
				t.Errorf("IDParam() = %v, want %v", got, tt.want)
			}
		})
	}
}
