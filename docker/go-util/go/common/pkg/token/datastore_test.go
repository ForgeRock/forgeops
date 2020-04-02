package token

import (
	"context"
	"testing"
	"time"

	"cloud.google.com/go/datastore"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/datastoreclient"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/httputil"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/store"
)

type datastoreTestSuite struct {
	suite.Suite
}

func TestTransactionTokenStoreSuite(t *testing.T) {
	suite.Run(t, new(datastoreTestSuite))
}

func (s *datastoreTestSuite) TestGet() {
	// given
	successKey := datastore.NameKey(DatastoreKind, "success_token", nil)
	successKey.Namespace = ""

	notFoundKey := datastore.NameKey(DatastoreKind, "not_found_token", nil)
	notFoundKey.Namespace = ""

	client := &datastoreclient.MockDataStorer{}
	client.
		On("Get", mock.Anything, successKey, mock.Anything).
		Run(func(args mock.Arguments) {
			existingEntity := args.Get(2).(*DatastoreEntity)
			existingEntity.Kind = TokenKindPasswordResetRequest
			existingEntity.UserID = "ABCD"
			existingEntity.UserType = UserTypeEndUser
			existingEntity.ExpirationUTC = 3
			existingEntity.CompletedUTC = 0
			existingEntity.CreatedUTC = 1
		}).
		Return(nil).
		On("Get", mock.Anything, notFoundKey, mock.Anything).
		Return(datastore.ErrNoSuchEntity)

	store := NewStore(store.Config{Namespace: "", Client: client})
	ctx, cancel := httputil.ContextWithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	// when
	successEntity, successErr := store.GetByToken(ctx, successKey.Name)
	notFoundEntity, notFoundErr := store.GetByToken(ctx, notFoundKey.Name)

	// then
	require.NoError(s.T(), successErr)
	require.Equal(s.T(), successKey.Name, successEntity.Token)

	require.Error(s.T(), notFoundErr, ErrEntityNotFound)
	require.Nil(s.T(), notFoundEntity)
}

func (s *datastoreTestSuite) TestCreateSuccess() {
	// given
	client := &datastoreclient.MockDataStorer{}
	client.
		On("Put", mock.Anything, mock.Anything, mock.Anything).
		Return(nil, nil)

	store := NewStore(store.Config{Namespace: "", Client: client})
	ctx, cancel := httputil.ContextWithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	// when
	e, err := store.Create(ctx, TokenKindPasswordResetRequest, "ABCD", UserTypeEndUser, nil)

	// then
	require.NoError(s.T(), err)
	require.NotEmpty(s.T(), e.Token)
	require.NotZero(s.T(), e.CreatedUTC)
	require.NotZero(s.T(), e.ExpirationUTC)
	require.Zero(s.T(), e.CompletedUTC)
}

func (s *datastoreTestSuite) TestCompleteSuccess() {
	// given
	token := "0123-ABCD"
	successKey := datastore.NameKey(DatastoreKind, token, nil)

	tx := &datastoreclient.MockDataStorerTransaction{}
	tx.
		On("Get", successKey, mock.Anything).
		Run(func(args mock.Arguments) {
			existingEntity := args.Get(1).(*DatastoreEntity)
			existingEntity.Kind = TokenKindPasswordResetRequest
			existingEntity.UserID = "ABCD"
			existingEntity.UserType = UserTypeEndUser
			existingEntity.ExpirationUTC = time.Now().Add(time.Minute).Unix()
			existingEntity.CompletedUTC = 0
			existingEntity.CreatedUTC = 1
		}).
		Return(nil).
		On("Put", mock.Anything, mock.Anything).
		Return(nil, nil).
		On("Rollback").
		Return(nil).
		On("Commit", mock.Anything).
		Return(nil, nil)

	client := &datastoreclient.MockDataStorer{}
	client.
		On("NewTransaction", mock.Anything).
		Return(tx, nil)

	store := NewStore(store.Config{Namespace: "", Client: client})
	ctx, cancel := httputil.ContextWithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	// when
	e, err := store.Complete(ctx, token)

	// then
	require.NoError(s.T(), err)
	require.NotZero(s.T(), e.CompletedUTC)
}
