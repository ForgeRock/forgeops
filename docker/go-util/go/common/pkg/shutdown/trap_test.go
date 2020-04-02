package shutdown

import (
	"context"
	"testing"
	"time"
)

func TestWaitForShutdown(t *testing.T) {
	trap := newTrap()
	started, completed := make(chan struct{}), make(chan struct{})
	go func() {
		defer close(completed)
		close(started)
		<-trap.ShuttingDown()
	}()
	<-started
	if !isWaiting(completed) {
		t.Fail()
	}
	trap.TriggerShutdown()
	if isWaiting(completed) {
		t.Fail()
	}
}

func TestEmptyWaitForGoroutines(t *testing.T) {
	trap := newTrap()
	started, completed := make(chan struct{}), make(chan struct{})
	go func() {
		defer close(completed)
		close(started)
		trap.WaitGracefully()
	}()
	<-started
	if isWaiting(completed) {
		t.Fail()
	}
}

func TestWaitForOneGoroutine(t *testing.T) {
	trap := newTrap()
	trap.Register("testroutine")
	started, completed := make(chan struct{}), make(chan struct{})
	go func() {
		defer close(completed)
		close(started)
		trap.WaitGracefully()
	}()
	<-started
	if !isWaiting(completed) {
		t.Fail()
	}
	trap.Done("testroutine")
	if isWaiting(completed) {
		t.Fail()
	}
}

func TestWaitForManyGoroutines(t *testing.T) {
	trap := newTrap()
	trap.Register("testroutine1")
	trap.Register("testroutine2")
	trap.Register("testroutine3")
	started, completed := make(chan struct{}), make(chan struct{})
	go func() {
		defer close(completed)
		close(started)
		trap.WaitGracefully()
	}()
	<-started
	if !isWaiting(completed) {
		t.Fail()
	}
	trap.Done("testroutine3")
	if !isWaiting(completed) {
		t.Fail()
	}
	trap.Done("testroutine1")
	if !isWaiting(completed) {
		t.Fail()
	}
	trap.Done("testroutine2")
	if isWaiting(completed) {
		t.Fail()
	}
}

func isWaiting(completed chan struct{}) bool {
	timeout, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()
	var waiting bool
	select {
	case <-completed:
		waiting = false
	case <-timeout.Done():
		waiting = true
	}
	return waiting
}
