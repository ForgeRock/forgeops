package rpc

import "github.com/osamingo/jsonrpc"

type (
	HandleParamsResulter interface {
		jsonrpc.Handler
		Name() string
		Params() interface{}
		Result() interface{}
	}
	Servicer interface {
		MethodName(HandleParamsResulter) string
		Handlers() []HandleParamsResulter
	}
)
