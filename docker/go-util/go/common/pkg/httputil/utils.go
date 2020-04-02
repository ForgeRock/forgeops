package httputil

import (
	"errors"
	"strconv"

	"context"
	"time"

	"github.com/gin-gonic/gin"
)

var (
	// ErrInvalidIDParam error indicates an invalid or missing ID parameter found in HTTP request.
	ErrInvalidIDParam = errors.New("Invalid or missing ID param")
)

// IDParam function
func IDParam(ginContext *gin.Context) (int64, error) {
	var id int64
	if len(ginContext.Param("id")) != 0 {
		id, _ = strconv.ParseInt(ginContext.Param("id"), 10, 64)
		if id > 0 {
			return id, nil
		}
	}
	return 0, ErrInvalidIDParam
}

func HasParam(key string, c *gin.Context) bool {
	return len(c.Param(key)) != 0
}

func ContextWithTimeout(ctx context.Context, timeout time.Duration) (context.Context, context.CancelFunc) {
	if timeout == time.Duration(0) {
		timeout = time.Duration(30 * time.Second)
	}
	return context.WithTimeout(ctx, timeout)
}
