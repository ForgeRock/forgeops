package testutil

import "net"

// Find a free port
// Thanks to https://github.com/phayes/freeport/blob/e5b3e0bfffdfb2ce90022bba2cda67653b152b7f/freeport.go
// Copyright (c) 2014, Patrick Hayes / HighWire Press All rights reserved.
func GetFreePort() (int, error) {
	addr, err := net.ResolveTCPAddr("tcp", "localhost:0")
	if err != nil {
		return 0, err
	}

	l, err := net.ListenTCP("tcp", addr)
	if err != nil {
		return 0, err
	}
	defer l.Close()
	return l.Addr().(*net.TCPAddr).Port, nil
}
