package token

import (
	"context"
	"time"

	"cloud.google.com/go/datastore"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/datastoreclient"
)

// TransactionTokenStorer is the datastore layer for transaction token records.
type TransactionTokenStorer interface {
	Create(ctx context.Context, kind TokenKind, userID string, userType UserType, lifetime *time.Duration) (*TokenEntity, error)
	CreateWithTransaction(ctx context.Context, tx datastoreclient.DataStorerTransaction, kind TokenKind, userID string, userType UserType, lifetime *time.Duration) (*TokenEntity, error)
	GetByToken(ctx context.Context, token string) (*TokenEntity, error)
	Complete(ctx context.Context, token string) (*TokenEntity, error)
	Expire(ctx context.Context, token string) (*TokenEntity, error)
	NewTransaction(ctx context.Context, opts ...datastore.TransactionOption) (datastoreclient.DataStorerTransaction, error)
	GetWithTransaction(ctx context.Context, tx datastoreclient.DataStorerTransaction, token string) (*TokenEntity, error)
	CompleteWithTransaction(ctx context.Context, tx datastoreclient.DataStorerTransaction, token string) (*TokenEntity, error)
	ExpireWithTransaction(ctx context.Context, tx datastoreclient.DataStorerTransaction, token string) (*TokenEntity, error)
}
