package profiler

import (
	log "github.com/sirupsen/logrus"

	stackdriver "cloud.google.com/go/profiler"
)

func Stackdriver(projectID string, serviceName string, serviceVersion string) {
	err := stackdriver.Start(stackdriver.Config{
		DebugLogging:   false,
		MutexProfiling: true,
		ProjectID:      projectID,
		Service:        serviceName,
		ServiceVersion: serviceVersion,
	})
	if err != nil {
		log.Warnf("Failed to start stackdriver profiler: %v", err)
	}
}
