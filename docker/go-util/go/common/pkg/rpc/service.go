package rpc

import "github.com/osamingo/jsonrpc"

type Service struct {
	MethodPrefix   string
	MethodHandlers []HandleParamsResulter
}

func (s Service) MethodName(h HandleParamsResulter) string {
	return s.MethodPrefix + "." + h.Name()
}
func (s Service) Handlers() []HandleParamsResulter {
	return s.MethodHandlers
}

type ServiceHandler struct {
	jsonrpc.Handler
	params interface{}
	result interface{}
	name   string
}

func NewServiceHandler(params, result interface{}, name string) *ServiceHandler {
	return &ServiceHandler{
		params: params,
		result: result,
		name:   name,
	}
}

func (h ServiceHandler) Name() string {
	return h.name
}
func (h ServiceHandler) Params() interface{} {
	return h.params
}
func (h ServiceHandler) Result() interface{} {
	return h.result
}
