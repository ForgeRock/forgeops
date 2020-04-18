package token

import (
	"context"
	"time"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/datastoreclient"

	"cloud.google.com/go/datastore"
	"github.com/dchest/uniuri"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/store"
)

const (
	// DatastoreKind kind for transaction tokens
	DatastoreKind = "TransactionToken"
	tokenLength   = 64
)

// Store configuration
type Store struct {
	store.Config
}

// NewStore initializes the Store.
func NewStore(config store.Config) *Store {
	return &Store{
		Config: config,
	}
}

func (s Store) key(token string) *datastore.Key {
	key := datastore.NameKey(DatastoreKind, token, nil)
	key.Namespace = s.Namespace
	return key
}

// Create generates a new token and uses it as the key for a new record in the TransactionToken datastore.
// TODO: Consider refactoring to either change name to something that doesn't sound like creating in memory object or
// split the object creation step. Maybe PUT or such.
func (s Store) Create(
	ctx context.Context,
	kind TokenKind,
	userID string,
	userType UserType,
	lifetime *time.Duration,
) (*TokenEntity, error) {

	now := time.Now()

	de := DatastoreEntity{
		Kind:          kind,
		UserID:        userID,
		UserType:      userType,
		CreatedUTC:    now.Unix(),
		ExpirationUTC: expirationUTCOrDefault(lifetime),
		CompletedUTC:  0,
	}

	var err error
	if err = validate(de); err != nil {
		return nil, err
	}

	token := uniuri.NewLen(tokenLength)
	key := s.key(token)
	_, err = s.Client.Put(ctx, key, &de)
	if err != nil {
		return nil, err
	}

	return &TokenEntity{
		Token:           key.Name,
		DatastoreEntity: de,
	}, nil
}

func (s Store) CreateWithTransaction(
	ctx context.Context,
	tx datastoreclient.DataStorerTransaction,
	kind TokenKind,
	userID string,
	userType UserType,
	lifetime *time.Duration,
) (*TokenEntity, error) {

	now := time.Now()

	de := DatastoreEntity{
		Kind:          kind,
		UserID:        userID,
		UserType:      userType,
		CreatedUTC:    now.Unix(),
		ExpirationUTC: expirationUTCOrDefault(lifetime),
		CompletedUTC:  0,
	}

	var err error
	if err = validate(de); err != nil {
		return nil, err
	}

	token := uniuri.NewLen(tokenLength)
	key := s.key(token)
	_, err = tx.Put(key, &de)
	if err != nil {
		return nil, err
	}

	return &TokenEntity{
		Token:           key.Name,
		DatastoreEntity: de,
	}, nil
}

func expirationUTCOrDefault(lifetime *time.Duration) int64 {
	now := time.Now()

	var expirationUTC time.Time

	if lifetime != nil {
		expirationUTC = now.Add(*lifetime)
	} else {
		expirationUTC = now.Add(defaultExpirationDays)
	}

	return expirationUTC.Unix()
}

// GetByToken returns the entity with the specified token.
func (s Store) GetByToken(ctx context.Context, token string) (*TokenEntity, error) {

	key := s.key(token)
	var de DatastoreEntity
	err := s.Client.Get(ctx, key, &de)
	if err != nil {
		return nil, err
	}

	return &TokenEntity{
		Token:           key.Name,
		DatastoreEntity: de,
	}, nil
}

func (s Store) GetWithTransaction(ctx context.Context, tx datastoreclient.DataStorerTransaction, token string) (*TokenEntity, error) {

	key := s.key(token)
	var de DatastoreEntity
	err := tx.Get(key, &de)
	if err != nil {
		return nil, err
	}

	return &TokenEntity{
		Token:           key.Name,
		DatastoreEntity: de,
	}, nil
}

// Complete updates CompletedUTC and ExpiredUTC to the current time.
func (s Store) Complete(ctx context.Context, token string) (*TokenEntity, error) {

	tx, err := s.Client.NewTransaction(ctx)
	if err != nil {
		return nil, err
	}
	entity, err := s.CompleteWithTransaction(ctx, tx, token)
	if err != nil {
		_ = tx.Rollback()
		return nil, err
	}
	if _, err := tx.Commit(); err != nil {
		_ = tx.Rollback()
		return nil, err
	}
	return entity, nil
}

// CompleteWithTransaction updates CompletedUTC and ExpiredUTC to the current time.
func (s Store) CompleteWithTransaction(
	ctx context.Context,
	tx datastoreclient.DataStorerTransaction,
	token string,
) (*TokenEntity, error) {

	key := s.key(token)
	dsEntity := new(DatastoreEntity)

	if err := tx.Get(key, dsEntity); err != nil {
		if err == datastore.ErrNoSuchEntity {
			return nil, ErrEntityNotFound
		}
		return nil, err
	}

	if dsEntity.CompletedUTC > 0 {
		return nil, ErrTokenAlreadyComplete
	}

	now := time.Now().Unix()
	if dsEntity.ExpirationUTC < now {
		return nil, ErrTokenExpired
	}

	dsEntity.CompletedUTC = now
	dsEntity.ExpirationUTC = dsEntity.CompletedUTC

	if err := validate(*dsEntity); err != nil {
		return nil, err
	}

	if _, err := tx.Put(key, dsEntity); err != nil {
		return nil, err
	}

	return &TokenEntity{
		Token:           token,
		DatastoreEntity: *dsEntity,
	}, nil
}

// Expire updates the ExpirationUTC to the current time.
func (s Store) Expire(ctx context.Context, token string) (*TokenEntity, error) {

	tx, err := s.Client.NewTransaction(ctx)
	if err != nil {
		return nil, err
	}
	entity, err := s.ExpireWithTransaction(ctx, tx, token)
	if err != nil {
		_ = tx.Rollback()
		return nil, err
	}
	if _, err := tx.Commit(); err != nil {
		_ = tx.Rollback()
		return nil, err
	}
	return entity, nil
}

// Expire updates the ExpirationUTC to the current time.
func (s Store) ExpireWithTransaction(
	ctx context.Context,
	tx datastoreclient.DataStorerTransaction,
	token string,
) (*TokenEntity, error) {

	key := s.key(token)
	dsEntity := new(DatastoreEntity)

	if err := tx.Get(key, dsEntity); err != nil {
		if err == datastore.ErrNoSuchEntity {
			return nil, ErrEntityNotFound
		}
		return nil, err
	}

	now := time.Now().Unix()
	if dsEntity.ExpirationUTC < now {
		return nil, ErrTokenExpired
	}

	dsEntity.ExpirationUTC = now

	if err := validate(*dsEntity); err != nil {
		return nil, err
	}

	if _, err := tx.Put(key, dsEntity); err != nil {
		return nil, err
	}

	return &TokenEntity{
		Token:           token,
		DatastoreEntity: *dsEntity,
	}, nil
}

func (s Store) NewTransaction(ctx context.Context, opts ...datastore.TransactionOption) (datastoreclient.DataStorerTransaction, error) {
	return s.Client.NewTransaction(ctx, opts...)
}
