package httputil

import (
	"errors"
	"reflect"
	"testing"
)

func TestNewErrorResponse(t *testing.T) {
	type args struct {
		err error
	}
	err1 := errors.New("new error")
	tests := []struct {
		name string
		args args
		want *ErrorResponseBody
	}{
		{"error response", args{err: err1}, &ErrorResponseBody{Errors: MapError(err1)}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := NewErrorResponse(tt.args.err); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("NewErrorResponse() = %v, want %v", got, tt.want)
			}
		})
	}
}
