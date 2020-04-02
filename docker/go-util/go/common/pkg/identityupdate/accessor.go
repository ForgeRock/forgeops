package identityupdate

import (
	"errors"
	"fmt"
	"io/ioutil"
	"strings"

	"gopkg.in/src-d/go-billy.v4"
)

// Type representing the 'intent' to search for something in a YAML file using jsonpath-like dot notation access
// See accessor_test.go for examples of how it is used
// Could change in future to use a special jsonpath query or something, currently just handles dot notation access
type YamlAccessor struct {
	// list of things to search for from split dot notation.
	state []string
	// Original thing searched for - should only be used in error messages.
	original []string
}

// Turn field accessor string (ONLY handles dot notation like a.b.c, not any fancy querying at the moment) into correct type
func NewAccessor(field string) (*YamlAccessor, error) {
	split := strings.Split(field, ".")
	for _, s := range split {
		if s == "" {
			return nil, errors.New("empty accessor")
		}
	}
	return &YamlAccessor{split, split}, nil
}

// Given the accessor state, try to find the value in the given map
func (y YamlAccessor) findInMap(unmarshaled map[interface{}]interface{}) (string, error) {
	next, nextState := y.state[0], y.state[1:]

	log.Debugf("Trying to look for '%s' in map", next)
	val, ok := unmarshaled[next]

	if !ok {
		return "", fmt.Errorf("could not find '%s' in map", next)
	}

	if len(nextState) == 0 {
		conv, ok := val.(string)
		if !ok {
			return "", fmt.Errorf("found '%s' in map but it was not a string", y.original)
		}
		return conv, nil
	} else {
		conv, ok := val.(map[interface{}]interface{})
		if !ok {
			err := fmt.Errorf("expected dict mapping")
			log.WithError(err).WithField("value", val).Error("error converting value to map")
			return "", err
		}
		nextAccessor := YamlAccessor{
			state:    nextState,
			original: y.original,
		}
		return nextAccessor.findInMap(conv)
	}
}

// Given accessor state, find something in a file
func (y YamlAccessor) findInFile(file billy.File) (string, error) {
	if file == nil {
		err := errors.New("nil file given")
		return "", err
	}

	err := rewindFile(file)
	if err != nil {
		return "", nil
	}

	content, err := ioutil.ReadAll(file)
	if err != nil {
		log.WithError(err).Error("Error reading input file")
		return "", err
	}

	unmarshaled, err := unmarshalYaml(content)
	if err != nil {
		return "", err
	}

	return y.findInMap(unmarshaled)
}
