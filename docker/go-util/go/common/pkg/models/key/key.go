package key

import (
	"cloud.google.com/go/datastore"
)

// Keyer provides an interface to get/set *datastore.Key
type Keyer interface {
	GetKey() *datastore.Key
	SetKey(*datastore.Key)
}

// Key is an embeddable interface to
// handled datastore json encoded keys
type Key struct {
	Key *datastore.Key `datastore:"__key__" json:"id"`
}

func (k *Key) GetKey() *datastore.Key {
	return k.Key
}

func (k *Key) SetKey(key *datastore.Key) {
	k.Key = key
}
