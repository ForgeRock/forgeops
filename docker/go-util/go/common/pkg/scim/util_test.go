package scim

import (
	"net/url"
	"testing"

	"github.com/stretchr/testify/assert"

	datastore "cloud.google.com/go/datastore"
)

func TestToDatastoreQuery(t *testing.T) {

	assert := assert.New(t)
	type args struct {
		query *datastore.Query
		url   *url.URL
	}
	type expected struct {
		err   error
		query *datastore.Query
	}
	collection := datastore.NewQuery("TestService").Namespace("TestNamespace")
	tests := []struct {
		name     string
		args     args
		expected expected
	}{
		{
			"successful datastore query",
			args{
				collection,
				&url.URL{
					Scheme:   "https",
					Host:     "forgerock.com",
					Path:     "",
					RawQuery: "filter=name eq HappyPath&filter=ok eq true&filter=key eq \"some value\"&sortBy=timestamp&sortOrder=descending",
				},
			},
			expected{
				err:   nil,
				query: collection.Filter("Name=", "HappyPath").Filter("Ok=", true).Filter("Key=", "some value").Order("-Timestamp"),
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			query, err := ToDatastoryQuery(tt.args.query, tt.args.url)
			assert.Equal(tt.expected.query, query)
			assert.Equal(tt.expected.err, err)
		})
	}
}
