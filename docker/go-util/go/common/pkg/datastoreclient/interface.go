package datastoreclient

import (
	"context"

	"cloud.google.com/go/datastore"
)

// DataStorer is a datastore client interface that changes the contract of some functions
// by introducing DataStorerIterator and DataStorerTransaction interfaces, for ease of testing.
// See https://godoc.org/cloud.google.com/go/datastore#Client
type DataStorer interface {
	// AllocateIDs https://godoc.org/cloud.google.com/go/datastore#Client.AllocateIDs
	AllocateIDs(ctx context.Context, keys []*datastore.Key) ([]*datastore.Key, error)

	// Close https://godoc.org/cloud.google.com/go/datastore#Client.Close
	Close() error

	// Count https://godoc.org/cloud.google.com/go/datastore#Client.Count
	Count(ctx context.Context, q *datastore.Query) (n int, err error)

	// Delete https://godoc.org/cloud.google.com/go/datastore#Client.Delete
	Delete(ctx context.Context, key *datastore.Key) error

	// DeleteMulti https://godoc.org/cloud.google.com/go/datastore#Client.DeleteMulti
	DeleteMulti(ctx context.Context, keys []*datastore.Key) (err error)

	// Get https://godoc.org/cloud.google.com/go/datastore#Client.Get
	Get(ctx context.Context, key *datastore.Key, dst interface{}) (err error)

	// GetAll https://godoc.org/cloud.google.com/go/datastore#Client.GetAll
	GetAll(ctx context.Context, q *datastore.Query, dst interface{}) (keys []*datastore.Key, err error)

	// GetMulti https://godoc.org/cloud.google.com/go/datastore#Client.GetMulti
	GetMulti(ctx context.Context, keys []*datastore.Key, dst interface{}) (err error)

	// Mutate https://godoc.org/cloud.google.com/go/datastore#Client.Mutate
	Mutate(ctx context.Context, muts ...*datastore.Mutation) (ret []*datastore.Key, err error)

	// NewTransaction https://godoc.org/cloud.google.com/go/datastore#Client.NewTransaction
	NewTransaction(ctx context.Context, opts ...datastore.TransactionOption) (t DataStorerTransaction, err error)

	// Put https://godoc.org/cloud.google.com/go/datastore#Client.Put
	Put(ctx context.Context, key *datastore.Key, src interface{}) (*datastore.Key, error)

	// PutMulti https://godoc.org/cloud.google.com/go/datastore#Client.PutMulti
	PutMulti(ctx context.Context, keys []*datastore.Key, src interface{}) (ret []*datastore.Key, err error)

	// Run https://godoc.org/cloud.google.com/go/datastore#Client.Run
	Run(ctx context.Context, q *datastore.Query) DataStorerIterator

	// RunInTransaction https://godoc.org/cloud.google.com/go/datastore#Client.RunInTransaction
	RunInTransaction(ctx context.Context, f func(tx DataStorerTransaction) error, opts ...datastore.TransactionOption) (cmt *datastore.Commit, err error)
}

// DataStorerIterator is a datatore client result-iterator interface.
// See https://godoc.org/cloud.google.com/go/datastore#Iterator
type DataStorerIterator interface {
	// Cursor https://godoc.org/cloud.google.com/go/datastore#Iterator.Cursor
	Cursor() (c datastore.Cursor, err error)

	// Next https://godoc.org/cloud.google.com/go/datastore#Iterator.Next
	Next(dst interface{}) (k *datastore.Key, err error)
}

// DataStorerTransaction is a datatore client transaction interface.
// See https://godoc.org/cloud.google.com/go/datastore#Transaction
type DataStorerTransaction interface {
	// Commit https://godoc.org/cloud.google.com/go/datastore#Transaction.Commit
	Commit() (c *datastore.Commit, err error)

	// Delete https://godoc.org/cloud.google.com/go/datastore#Transaction.Delete
	Delete(key *datastore.Key) error

	// DeleteMulti https://godoc.org/cloud.google.com/go/datastore#Transaction.DeleteMulti
	DeleteMulti(keys []*datastore.Key) (err error)

	// Get https://godoc.org/cloud.google.com/go/datastore#Transaction.Get
	Get(key *datastore.Key, dst interface{}) (err error)

	// GetMulti https://godoc.org/cloud.google.com/go/datastore#Transaction.GetMulti
	GetMulti(keys []*datastore.Key, dst interface{}) (err error)

	// Mutate https://godoc.org/cloud.google.com/go/datastore#Transaction.Mutate
	Mutate(muts ...*datastore.Mutation) ([]*datastore.PendingKey, error)

	// Put https://godoc.org/cloud.google.com/go/datastore#Transaction.Put
	Put(key *datastore.Key, src interface{}) (*datastore.PendingKey, error)

	// PutMulti https://godoc.org/cloud.google.com/go/datastore#Transaction.PutMulti
	PutMulti(keys []*datastore.Key, src interface{}) (ret []*datastore.PendingKey, err error)

	// Rollback https://godoc.org/cloud.google.com/go/datastore#Transaction.Rollback
	Rollback() (err error)
}
