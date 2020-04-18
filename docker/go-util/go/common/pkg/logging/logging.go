package logging

import (
	"bytes"
	"os"
	"path"
	"runtime"
	"strconv"
	"time"

	"github.com/sirupsen/logrus"
)

var (
	Recorder *logrus.Logger
	Record   *logrus.Entry
)

const (
	InfoLevel  = logrus.InfoLevel
	DebugLevel = logrus.DebugLevel
)

// Default options for new loggers
var defaultSpec = struct {
	hooks        []logrus.Hook
	formatter    logrus.Formatter
	reportCaller bool
	level        logrus.Level
}{
	hooks: []logrus.Hook{new(SafeHook)},
	formatter: &logrus.JSONFormatter{
		FieldMap: logrus.FieldMap{
			logrus.FieldKeyTime:  "timestamp",
			logrus.FieldKeyLevel: "severity",
			logrus.FieldKeyMsg:   "message",
		},
		CallerPrettyfier: func(f *runtime.Frame) (string, string) {
			_, filename := path.Split(f.File)
			return f.Function, filename + ":" + strconv.Itoa(f.Line)
		},
		TimestampFormat: time.RFC3339Nano,
	},
	reportCaller: true,
	level:        logrus.InfoLevel,
}

// Set the defaults on this logger
func setDefaults(logger *logrus.Logger) {
	for _, h := range defaultSpec.hooks {
		logger.AddHook(h)
	}
	logger.SetReportCaller(defaultSpec.reportCaller)
	logger.SetFormatter(defaultSpec.formatter)
	logger.SetLevel(defaultSpec.level)
}

// init() initialize global logrus settings
func init() {
	// set the log level based on the value of the LOG_LEVEL environment variable (defaults to 'info')
	level := os.Getenv("LOG_LEVEL")
	if len(level) == 0 {
		level = "info"
	}
	if logLevel, err := logrus.ParseLevel(level); err != nil {
		logrus.WithError(err).Warn("log init failed. Level set to Debug")
		defaultSpec.level = DebugLevel
	} else {
		defaultSpec.level = logLevel
	}

	setDefaults(logrus.StandardLogger())
	// Split output to STDERR or STDOUT depending on error level.
	// logrus sends all log output to STDERR by default and have communicated
	// they don't intend to fix this internally
	logrus.SetOutput(&OutputSplitter{})

	// new global logging objects: setup
	// this should live alongside the logrus package default until we completely convert
	Recorder = logrus.New()
	setDefaults(Recorder)
	Recorder.SetOutput(os.Stdout)
	// ensure that logrus.Logger.newEntry() is called
	Record = Recorder.WithField("logger-type", "global default")
}

type OutputSplitter struct{}

func (splitter *OutputSplitter) Write(p []byte) (n int, err error) {
	if bytes.Contains(p, []byte("\"level\":\"error\"")) ||
		bytes.Contains(p, []byte("\"level\":\"fatal\"")) {
		return os.Stderr.Write(p)
	}
	return os.Stdout.Write(p)
}

type LogWriter struct {
	Logger *logrus.Entry
	Level  logrus.Level
}

func (w LogWriter) Write(p []byte) (n int, err error) {
	lenp := len(p)
	s := string(p)
	w.Logger.Log(w.Level, s)
	return lenp, nil
}

// SafeHook hide sensitive information from log statement.
// The hook operates before the Formatter and before the
// log statement is written.
// It checks whether a logging field implements SafelyLoggable
// If if does, LogSafeCopy is invoked to get a copy of the field
// without the sensitive information.
// If it does not, the element will be logged as-is.
type SafeHook struct {
}

func (f *SafeHook) Fire(entry *logrus.Entry) error {
	data := logrus.Fields{}
	for k, v := range entry.Data {
		data[k] = LogSafeCopy(v)
	}
	entry.Data = data
	return nil
}

func (f *SafeHook) Levels() []logrus.Level {
	return logrus.AllLevels
}

type SafelyLoggable interface {
	LogSafeCopy() interface{}
}

func LogSafeCopy(original interface{}) interface{} {
	safelyLoggable, ok := original.(SafelyLoggable)
	if ok {
		copied := safelyLoggable.LogSafeCopy()
		return copied
	}
	return original
}
