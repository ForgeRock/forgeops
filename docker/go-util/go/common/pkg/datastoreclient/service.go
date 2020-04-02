package datastoreclient

import (
	context "context"
	"fmt"

	datastore "cloud.google.com/go/datastore"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/models/key"
)

// Servicer implements basic CRUD operations
type Servicer interface {
	Delete(ctx context.Context, encKey string) error
	Get(ctx context.Context, encKey string, dst key.Keyer) error
	Save(ctx context.Context, key *datastore.Key, src key.Keyer) error
	Query(ctx context.Context, qf QueryFilter, dst interface{}) error
}

// ServiceConfig for Service
type ServiceConfig struct {
	Client    DataStorer
	Kind      string
	Namespace string
}

// Service is a basic embeddable service
// for interacting with gcloud datastore
type Service struct {
	ServiceConfig
}

type QueryFilter func(q *datastore.Query) (*datastore.Query, error)

func NewService(config ServiceConfig) *Service {
	return &Service{
		ServiceConfig: config,
	}
}

// Delete objects by encoded key
func (s *Service) Delete(ctx context.Context, encKey string) error {
	key, err := datastore.DecodeKey(encKey)
	if err != nil {
		return err
	}
	return s.Client.Delete(ctx, key)
}

// Get objects by encoded key and assigns to dst pointer
func (s *Service) Get(ctx context.Context, encKey string, dst key.Keyer) error {
	key, err := datastore.DecodeKey(encKey)
	if err != nil {
		return fmt.Errorf("Invalid Key: %s", err.Error())
	}
	err = s.Client.Get(ctx, key, dst)
	if err != nil {
		return err
	}
	return nil
}

// NewKey generates a new Namspace/Kind key
func (s *Service) NewKey() *datastore.Key {
	return &datastore.Key{
		Kind:      s.Kind,
		Namespace: s.Namespace,
	}
}

// Save upserts src pointer by key, if key is not provided a new key is generated
func (s *Service) Save(ctx context.Context, key *datastore.Key, src key.Keyer) (err error) {
	if key == nil {
		key = s.NewKey()
	}
	key, err = s.Client.Put(ctx, key, src)
	if err != nil {
		return err
	}
	src.SetKey(key)
	return nil
}

// Query gets all objects satisfying the datastore.Query returned from QueryFilter
func (s *Service) Query(ctx context.Context, filter QueryFilter, dst interface{}) (err error) {
	query := datastore.NewQuery(s.Kind).Namespace(s.Namespace)
	query, err = filter(query)
	if err != nil {
		return err
	}
	_, err = s.Client.GetAll(ctx, query, dst)
	if err != nil {
		return err
	}
	return nil
}
