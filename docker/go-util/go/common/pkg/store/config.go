package store

import (
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/datastoreclient"
)

// Config is a common NewStore configuration type
type Config struct {
	Client datastoreclient.DataStorer
	// An empty namespace is the default namespace
	Namespace string
}
