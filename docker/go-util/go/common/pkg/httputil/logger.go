package httputil

import (
	"fmt"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

func Logger(notlogged []string) gin.HandlerFunc {
	logger := logrus.StandardLogger()
	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}

	var skip map[string]struct{}

	if length := len(notlogged); length > 0 {
		skip = make(map[string]struct{}, length)

		for _, path := range notlogged {
			skip[path] = struct{}{}
		}
	}

	return func(c *gin.Context) {
		// Start timer
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		// Process request
		c.Next()

		// Log only when path is not being skipped
		if _, ok := skip[path]; !ok {
			end := time.Now()
			latency := end.Sub(start)

			clientIP := c.ClientIP()
			method := c.Request.Method
			clientUserAgent := c.Request.UserAgent()
			statusCode := c.Writer.Status()
			referer := c.Request.Referer()
			dataLength := c.Writer.Size()
			if dataLength < 0 {
				dataLength = 0
			}

			if raw != "" {
				path = path + "?" + raw
			}

			entry := logger.WithFields(logrus.Fields{
				"hostname":   hostname,
				"statusCode": statusCode,
				"latency":    latency,
				"clientIP":   clientIP,
				"method":     method,
				"path":       path,
				"referer":    referer,
				"dataLength": dataLength,
				"userAgent":  clientUserAgent,
			})

			if len(c.Errors) > 0 {
				entry.Error(c.Errors.ByType(gin.ErrorTypePrivate).String())
			} else {
				msg := fmt.Sprintf("GIN - %s - %s %s %s %d", hostname, clientIP, method, path, statusCode)
				if statusCode > 499 {
					entry.Error(msg)
				} else if statusCode > 399 {
					entry.Warn(msg)
				} else {
					entry.Info(msg)
				}
			}
		}
	}
}
