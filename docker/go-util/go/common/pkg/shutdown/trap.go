package shutdown

import (
	"context"
	"os"
	"os/signal"
	"runtime"
	"sync"
	"syscall"

	log "github.com/sirupsen/logrus"
)

type Trap struct {
	Ctx       context.Context
	ctxCancel context.CancelFunc
	log       *log.Entry
	once      *sync.Once
	wg        *sync.WaitGroup
	routines  []string
	mux       *sync.Mutex
}

func (t *Trap) TriggerShutdown() {
	if file, line, name, ok := caller(); ok {
		t.log.Debugf("Shutdown triggered from %s(%s:%d), notifying registered goroutines: %s", name, file, line, t.routines)
	} else {
		t.log.Debugf("Shutdown triggered from unknown location, notifying registered goroutines: %s", t.routines)
	}
	t.once.Do(func() { t.ctxCancel() })
}

func (t *Trap) WaitGracefully() {
	t.log.Debug("Waiting for goroutines to shutdown")
	t.wg.Wait()
}

func (t *Trap) Register(routine string) {
	t.mux.Lock()
	defer t.mux.Unlock()
	if file, line, name, ok := caller(); ok {
		t.log.Debugf("Registered %s for shutdown from %s(%s:%d)", routine, name, file, line)
	} else {
		t.log.Debugf("Registered %s from unknown goroutine for shutdown", routine)
	}
	t.routines = append(t.routines, routine)
	t.wg.Add(1)
}

// Obtain the function name and definition location if possible, so that we can log where the registration is coming from
func caller() (file string, line int, name string, ok bool) {
	pc, file, line, ok := runtime.Caller(2)
	if ok {
		name = "unknown"
		if f := runtime.FuncForPC(pc); f != nil {
			name = f.Name()
		}
	}
	return
}

func (t *Trap) Done(routine string) {
	t.mux.Lock()
	defer t.mux.Unlock()
	t.wg.Done()
	for i, r := range t.routines {
		if r == routine {
			t.routines[len(t.routines)-1], t.routines[i] = t.routines[i], t.routines[len(t.routines)-1]
			t.routines = t.routines[:len(t.routines)-1]
			log.Debugf("Goroutine %s has completed", routine)
			return
		}
	}
	t.log.Fatalf("Unknown routine: %s", routine)
}

func (t *Trap) ShuttingDown() <-chan struct{} {
	return t.Ctx.Done()
}

func NewShutdownTrap() *Trap {
	quit := make(chan os.Signal)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	t := newTrap()
	go func() {
		defer t.TriggerShutdown()
		sig := <-quit
		t.log.Infof("Received %s signal, shutting down", sig)
	}()
	log.RegisterExitHandler(func() { t.TriggerShutdown() })
	return t
}

func newTrap() *Trap {
	ctx, cancel := context.WithCancel(context.Background())
	l := log.WithFields(log.Fields{
		"pkg": "shutdown",
		"svc": "Trap",
	})
	t := &Trap{ctx, cancel, l, &sync.Once{}, &sync.WaitGroup{}, make([]string, 0), &sync.Mutex{}}
	return t
}
