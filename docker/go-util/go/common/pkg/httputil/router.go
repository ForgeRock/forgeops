package httputil

import (
	"github.com/gin-gonic/gin"
)

func DefaultRouter(notLogged []string) *gin.Engine {
	router := gin.New()
	router.Use(Logger(notLogged), gin.Recovery())
	return router
}
