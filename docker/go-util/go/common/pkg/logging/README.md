# Common Logging Package

The package contains an init() function that will set the logging output to
JSON formatted strings and will send errors to STDERR and everything else to
STDOUT.

In order to have logging.go's init() function execute before any others you
will need to add the following code to the entry point file.

```go
import (
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/logging"
)
```

## Quick Start

The new common logger attempts to provide a simple logging mechanism for use
in all FRaaS Go applications.

The intention is to use common/pkg/logging everywhere, and avoid importing
logrus directly. There are more details in the Further Details section below,
but this should get you started.

Note that the common logger respects the value of the LOG_LEVEL environment
variable. By default, this is set to INFO for FRaaS Go applications. 

```go
import (
  "github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/logging"
)

func main() {
  // By default, this includes information about the calling function
  log := logging.Record
  
  // logging.Record is a logrus.Entry, so we can use standard logrus functions. E.g.
  log.Infof("Runtime Options: %+v", sanitizeAppOptions(*opts))
  log.Debug("This is a debug-level message")

  // If we need to add more fields, we can do so by defining a local context logger
  // and passing a map[string]interface{} to the WithFields function:
  contextLogger := log.WithFields(map[string]interface{}{
    "key0": "value0",
    "key1": []int{99,77,55},
  })
  
  // Alternatively we can call WithField multiple times. This is equivalent to the line above:
  contextLogger := log.WithField("key0", "value0").WithField("key1", []int{99, 77, 55})
  
  // contextLogger will now include the fields "key0" & "key1" on each entry call
  contextLogger.Info("this is informative")
  
  // but logging.Record will not include the new fields
  log.Debug("key0 and key1 missing")
}
```

## Further Details

### Global logrus.Logger Instance

For the sake of simplicity and maintainability, we need a single logger
object. An object that pushes you to log in a standard fashion but is
flexible (and global) enough to be easily managed.

The common logger is a wrapper around logrus, but we don't expect developers
to know logrus' nuances. The intention here is to make things simple, but
also to provide a common set of functions which can be tailored to our
logging requirements in a single location.

#### logrus vernacular
[logger](https://github.com/sirupsen/logrus/blob/master/logger.go) - the thing writing the logs (*how, where*); formatting define here  

[entry](https://github.com/sirupsen/logrus/blob/master/entry.go) - the actual log entry, the content  

[fields](https://github.com/sirupsen/logrus/blob/master/logrus.go#L10) - a map of key/value pairs meaningful to a entry or set of entries  
*logrus is pushing its users to lean on key/value pairs instead of a long and perhaps tough to parse message string*

#### A simple implementation example

```go
import (
  "github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/logging"
)

/*
  Previously, we imported logrus and aliased the package as 'log':
    log "github.com/sirupsen/logrus"

  Instead, we will import common/pkg/logging and use the package identifier: "logging".
  From then on we'll have access to two logging vars:
    • Recorder (logger)
    • Record (entry)

  To retain similar functionality with the previous method, we can create a `log` variable:
  log := logging.Record
*/

func main() {
  // We'll convert existing logging by defining a variable 'log' which is a logging.Record.
  // This calls logrus directly:
  log.Infof("Runtime Options: %+v", sanitizeAppOptions(*opts))

  // Using thew new logger, this will become:
  log := logging.Record
  log.Infof("Runtime Options: %+v", sanitizeAppOptions(*opts))

  // You can spin off a specific logging record but make sure the information you add is
  // useful; a poor signal to noise ratio can hinder troubleshooting and triage, and often
  // error messages in Go are sufficient on their own to understand the problem.
  contextLogger := logging.Record.WithFields(map[string]interface{}{
    "key0": "value0",
    "key1": []int{99,77,55},
  })
  // contextLogger will now include the fields "key0" & "key1" on each entry call
  contextLogger.Info("this is informative")
  // but logging.Record will not include the new fields
  logging.Record.Debug("key0 and key1 missing")


  // -- GLOBAL MODIFICATION --
  // or add fields globally:
  logging.Record = logging.Recorder.WithField("foo", "bar")
  // future calls pick up the field addition
  logging.Record.Warn("something changed")

  // create a black hole:
  logging.Recorder.SetOutput(ioutil.Discard)
  logging.Record.Info("never to be seen")
}

```
## General Logging Guidelines

Simple guidelines for sensible logging practice...

### Logging Error Messages

Try to pass errors back to the calling function, rather than writing a log
message at the point the error happens.

### Logging Levels

The common logger respects the value of the LOG_LEVEL environment variable.

Valid values are: TRACE, DEBUG, INFO, WARN, ERROR, FATAL, PANIC

#### For further discussion...

FRaaS components written in Go generally use the ‘logrus’ logging package
which includes the ability to log at the different levels specified above.

We probably only require two levels of logging; one for Normal Operation and
another for use when troubleshooting or developing, so we should use INFO for
Normal Operation, and set this as a default for all Go apps.

Any information we think would be useful for debugging or development purposes
should be logged at DEBUG level.

ERROR level should be used when handling errors - and if the error handling
requires the program to exit, then it’s acceptable to use FATAL.

##### What information should be logged?

In general, we should...

- Declare the action we’re about to attempt
- Be silent on success (at INFO level)
- Report success (preferably at DEBUG level)
- Report anything else we may need for development (at DEBUG level)
- Log any errors

## Sensitive data

The logger is configured with a `SafeHook` so that any sensitive data can
automatically be removed from the log outputs.

To do so, a struct must implements a `func (p T) LogSafeCopy() interface{}`
method in charge of returning the struct with the sensitive information
obfuscated.

Example:

```go
// ProjectInfo encapsulates a request to create a new Organization project
type ProjectInfo struct {
    // ProjectID is the immutable Google Project ID for an Organization
    ProjectID string `json:"project_id"`
    // UUID that groups related pub-sub messages together (e.g., steps in createProject process)
    UUID string `json:"uuid"`
    // AuthToken is the initial organization bearer-token for communicating with saas-ui, which proxies calls to saas-api
    AuthToken string `json:"authToken"`
    // OrganizationID is a unique, immutable identifier for an organization
    OrganizationID int64 `json:"organizationID"`
    // Subdomain for an organization's URL
    Subdomain string `json:"subdomain"`
    // OrgEngineDockerImageTag is the image tag for the org-engine pod
    OrgEngineDockerImageTag string `json:"orgEngineDockerImageTag"`
    // Docker image tag used for org-bootstrapper
    OrgBootstrapperDockerImageTag string `json:"orgBootstrapperDockerImageTag"`
}

func (p ProjectInfo) LogSafeCopy() interface{} {
    p.AuthToken = "[REDACTED]"
    return p
}
```

```go
log.WithField("project", p).Info("Project created")
```

Output:
```
"{"level":"info","msg":"Project created","project":{"project_id":"projectID","uuid":"UUID","authToken":"[REDACTED]",
  "organizationID":1234,"subdomain":"Subdomain","orgEngineDockerImageTag":"",
  "orgBootstrapperDockerImageTag":""},"time":"2019-07-03T22:40:09.715238855+02:00"}
```
