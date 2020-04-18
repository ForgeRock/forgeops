package identityupdate

import (
	"gopkg.in/src-d/go-billy.v4"
	"gopkg.in/yaml.v2"
)

// Read a specific yaml value from a file given the field accessor
func ReadYamlValueFromFile(file billy.File, field string) (string, error) {
	accessor, err := NewAccessor(field)
	if err != nil {
		return "", err
	}

	return accessor.findInFile(file)
}

// Unmarshal content from bytes to a generic map
func unmarshalYaml(content []byte) (map[interface{}]interface{}, error) {
	unmarshaled := make(map[interface{}]interface{})

	err := yaml.Unmarshal(content, &unmarshaled)
	if err != nil {
		log.WithError(err).Error("Error unmarshaling yaml")
		return nil, err
	}

	return unmarshaled, nil
}
