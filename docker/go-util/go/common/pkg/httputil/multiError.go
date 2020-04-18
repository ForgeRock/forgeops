package httputil

import (
	"errors"
	"fmt"
	"strings"

	"github.com/xeipuuv/gojsonschema"
	validator "gopkg.in/go-playground/validator.v8"
)

const ValidationErrMsg = "%s %s failed validation: %s"

type MultiError []error

func (m MultiError) Error() string {
	var response string

	for _, err := range m {
		response += err.Error() + "\n"
	}

	return response
}

func MapError(err error) []string {
	if err == nil {
		return nil
	}

	if errs, ok := err.(MultiError); ok {
		var mapped []string
		for _, err := range errs {
			mapped = append(mapped, strings.Title(err.Error()))
		}
		return mapped
	}

	if errs, ok := err.(validator.ValidationErrors); ok {
		var mapped []string
		for _, err := range errs {
			msg := fmt.Sprintf(ValidationErrMsg, err.Field, err.Kind, err.Tag)
			mapped = append(mapped, strings.Title(msg))
		}
		return mapped
	}

	return []string{strings.Title(err.Error())}
}

func ConvertToMultiError(src []gojsonschema.ResultError) MultiError {
	var response []error

	for _, err := range src {
		response = append(response, errors.New(err.String()))
	}

	return response
}
