package scim

import (
	"fmt"
	"net/url"
	"regexp"
	"strconv"
	"strings"

	datastore "cloud.google.com/go/datastore"
)

var InvalidFilterOperator = fmt.Errorf("invalid filter operator, use: eq, lt, or gt")
var InvalidFilterSyntax = fmt.Errorf("invalid filter syntax, use: filter=key eq \"some value\".")

var operatorRegexp = regexp.MustCompile(`\b(eq|gt|lt)\b`)
var operatorMap = map[string]string{
	"eq": "=",
	"lt": "<",
	"gt": ">",
}

//nolint:gosimple
// ToDatastoreQuery parses SCIM query syntax to *datastore.Query
func ToDatastoryQuery(query *datastore.Query, reqURL *url.URL) (*datastore.Query, error) {
	var err error
	reqQuery := reqURL.Query()
	for k, params := range reqQuery {
		switch k {
		case "filter":
			query, err = toDatastoreFilter(query, params)
			if err != nil {
				return nil, err
			}
			break
		}
	}
	// sortBy & sortOrder
	// https://tools.ietf.org/html/rfc7644#section-3.4.2.3
	sortBy := strings.Title(reqQuery.Get("sortBy"))
	if "" != sortBy {
		// default to ascending order
		switch strings.ToLower(reqQuery.Get("sortOrder")) {
		case "descending":
			sortBy = fmt.Sprintf("-%s", sortBy)
			break
		}
		query = query.Order(sortBy)
	}
	return query, nil
}

// toDatastoreFilter parses ?filter queries to *datastore.Query
// https://tools.ietf.org/html/rfc7644#section-3.4.2.2
func toDatastoreFilter(query *datastore.Query, filters []string) (*datastore.Query, error) {
	for _, filter := range filters {
		operator, err := toDatastoreOperator(filter)
		if err != nil {
			return nil, err
		}
		fragments := operatorRegexp.Split(filter, -1)
		if len(fragments) < 2 {
			return nil, InvalidFilterSyntax
		}
		key := strings.Title(strings.TrimSpace(fragments[0]))
		value := removeQuotes(fragments[1])
		// do not check for empty value, to allow for unset field queries
		if "" == key {
			return nil, InvalidFilterSyntax
		}
		var filterValue interface{}
		// basic check bool/float/int type
		if "false" == value || "true" == value {
			filterValue, _ = strconv.ParseBool(value)
		} else {
			if n, err := strconv.ParseFloat(value, 64); err == nil {
				filterValue = n
			} else if n, err := strconv.ParseInt(value, 10, 64); err == nil {
				filterValue = n
			} else {
				filterValue = value
			}
		}
		filterKey := fmt.Sprintf("%s%s", key, operator)
		query = query.Filter(filterKey, filterValue)
	}
	return query, nil
}

func removeQuotes(s string) string {
	length := len(s)
	s = strings.TrimSpace(s)
	if length <= 1 {
		return s
	}
	if s[0] == '"' {
		s = s[1:]
	}
	if s[len(s)-1] == '"' {
		s = s[:len(s)-1]
	}
	return s
}

func toDatastoreOperator(filter string) (string, error) {
	s := strings.TrimSpace(operatorRegexp.FindString(filter))
	if s == "" {
		return "", InvalidFilterOperator
	}
	if operator, ok := operatorMap[s]; ok {
		return operator, nil
	}
	return "", InvalidFilterOperator
}
