package templates

import (
	"context"
	"fmt"

	"cloud.google.com/go/datastore"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/datastoreclient"
	templateModels "github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/models/template"
)

type Store interface {
	datastoreclient.Servicer
	FindTemplateByType(ctx context.Context, tmplType string) (*templateModels.DatastoreEntity, error)
}

type store struct {
	datastoreclient.Service
}

// NewStore returns a template datastoreclient.Servicer
func NewStore(config datastoreclient.ServiceConfig) Store {
	return &store{
		datastoreclient.Service{
			ServiceConfig: config,
		},
	}
}

func (s *store) FindTemplateByType(ctx context.Context, tmplType string) (template *templateModels.DatastoreEntity, err error) {
	// find first template of type
	var result []templateModels.DatastoreEntity
	templateQuery := func(query *datastore.Query) (*datastore.Query, error) {
		return query.Filter("Type=", tmplType).Limit(1), nil
	}
	err = s.Query(ctx, templateQuery, &result)
	if err != nil {
		return
	}
	if result == nil || 0 == len(result) {
		return nil, nil
	}
	if len(result) > 1 {
		return nil, fmt.Errorf("more than one template for for type: %s", tmplType)
	}
	template = &result[0]
	return
}
