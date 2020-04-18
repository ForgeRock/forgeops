package datastoreclient

import (
	"context"

	"cloud.google.com/go/datastore"
)

// ClientAdapter wraps a Datastore Client to expose the DataStorer interface.
type ClientAdapter struct {
	*datastore.Client
}

// NewClientAdapter creates a new ClientAdapter.
func NewClientAdapter(client *datastore.Client) ClientAdapter {
	return ClientAdapter{client}
}

// NewTransaction creates a new TransactionAdapter.
func (a ClientAdapter) NewTransaction(ctx context.Context, opts ...datastore.TransactionOption) (t DataStorerTransaction, err error) {
	transaction, err := a.Client.NewTransaction(ctx, opts...)
	if err != nil {
		return nil, err
	}
	return TransactionAdapter{transaction}, nil
}

// RunInTransaction adapts the function callback argument using DataStorerTransaction.
func (a ClientAdapter) RunInTransaction(ctx context.Context, f func(tx DataStorerTransaction) error, opts ...datastore.TransactionOption) (cmt *datastore.Commit, err error) {
	c := func(transaction *datastore.Transaction) error {
		return f(TransactionAdapter{transaction})
	}
	return a.Client.RunInTransaction(ctx, c, opts...)
}

// Run a query and return a DataStorerIterator.
func (a ClientAdapter) Run(ctx context.Context, q *datastore.Query) DataStorerIterator {
	return IteratorAdapter{a.Client.Run(ctx, q)}
}

// IteratorAdapter wraps a Datastore Iterator to expose the DataStorerIterator interface.
type IteratorAdapter struct {
	*datastore.Iterator
}

// TransactionAdapter wraps a Datastore Transaction to expose the DataStorerTransaction interface.
type TransactionAdapter struct {
	*datastore.Transaction
}
