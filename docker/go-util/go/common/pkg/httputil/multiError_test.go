package httputil

import (
	"errors"
	"reflect"
	"testing"

	"github.com/davecgh/go-spew/spew"
	"github.com/xeipuuv/gojsonschema"
)

func TestConvertToMultiError(t *testing.T) {
	type args struct {
		src []gojsonschema.ResultError
	}
	emsg := "single error"
	ctx := "a: "
	jsCtx := gojsonschema.NewJsonContext("a", nil)
	//err := errors.New(emsg)
	e := &gojsonschema.ResultErrorFields{}
	e.SetContext(jsCtx)
	e.SetValue(nil)
	e.SetDescription(emsg)
	multiError := []gojsonschema.ResultError{e, e}
	// ': ' is to account for implied context it appears
	mError := MultiError{errors.New(ctx + emsg), errors.New(ctx + emsg)}
	singleError := []gojsonschema.ResultError{e}
	sError := MultiError{errors.New(ctx + emsg)}
	tests := []struct {
		name string
		args args
		want MultiError
	}{
		{"convert single error", args{src: singleError}, sError},
		{"convert multi error", args{src: multiError}, mError},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := ConvertToMultiError(tt.args.src); !reflect.DeepEqual(got, tt.want) {
				spew.Dump(got)
				spew.Dump(tt.want)
				t.Errorf("ConvertToMultiError() = %+v, want %+v", got, tt.want)
			}
		})
	}
}

func TestMultiError_Error(t *testing.T) {
	tests := []struct {
		name string
		m    MultiError
		want string
	}{
		{"emtpy sting", MultiError{}, ""},
		{"single string", MultiError{errors.New("error")}, "error\n"},
		{"double error string", MultiError{errors.New("error1"),
			errors.New("error")}, "error1\nerror\n"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.m.Error(); got != tt.want {
				t.Errorf("MultiError.Error() = %v, want %v", got, tt.want)
			}
		})
	}
}
