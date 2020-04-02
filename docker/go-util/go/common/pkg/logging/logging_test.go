package logging

import (
	"bytes"
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_logRecord(t *testing.T) {
	var writeTo bytes.Buffer
	logger := Recorder
	logger.SetOutput(&writeTo)

	logger.WithField("testName", t.Name()).Info("hello")

	type logOutput struct {
		File      string `json:"file"`
		Func      string `json:"func"`
		Message   string `json:"message"`
		Severity  string `json:"severity"`
		TestName  string `json:"testName"`
		Timestamp string `json:"timestamp"`
	}

	var toString = writeTo.String()

	if assert.NotEmpty(t, toString) {
		var output logOutput
		err := json.Unmarshal([]byte(toString), &output)
		if assert.NoError(t, err) {
			assert.Contains(t, output.File, "logging_test.go")
			assert.Equal(t, output.Func, "github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/logging.Test_logRecord")
			assert.Equal(t, output.Message, "hello")
			assert.Equal(t, output.Severity, "info")
			assert.Equal(t, output.TestName, "Test_logRecord")
		}
	}
}

func Test_defaultLevel(t *testing.T) {
	var writeTo bytes.Buffer
	logger := Recorder
	logger.SetOutput(&writeTo)

	logger.WithField("testName", t.Name()).Debug("hello")

	var toString = writeTo.String()
	assert.Empty(t, toString, "Default log level should be INFO")
}

type sensitive struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func (s sensitive) LogSafeCopy() interface{} {
	s.Password = "***"
	return s
}

func Test_safelog(t *testing.T) {
	var writeTo bytes.Buffer
	logger := Recorder
	logger.SetOutput(&writeTo)

	userInfo := sensitive{
		Username: "misterbean",
		Password: "p@ssw0rd",
	}
	logger.WithField("userInfo", userInfo).Info("hello")

	type logOutput struct {
		File      string    `json:"file"`
		Func      string    `json:"func"`
		Message   string    `json:"message"`
		Severity  string    `json:"severity"`
		UserInfo  sensitive `json:"userInfo"`
		Timestamp string    `json:"timestamp"`
	}

	var toString = writeTo.String()

	if assert.NotEmpty(t, toString) {
		var output logOutput
		err := json.Unmarshal([]byte(toString), &output)
		if assert.NoError(t, err) {
			assert.Contains(t, output.File, "logging_test.go")
			assert.Equal(t, output.Func, "github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/logging.Test_safelog")
			assert.Equal(t, output.Message, "hello")
			assert.Equal(t, output.Severity, "info")

			assert.Equal(t, output.UserInfo.Username, "misterbean")
			assert.Equal(t, output.UserInfo.Password, "***")

			assert.Equal(t, userInfo.Password, "p@ssw0rd")
		}
	}
}
