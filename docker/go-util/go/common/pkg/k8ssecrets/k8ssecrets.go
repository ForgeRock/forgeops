package k8ssecrets

import (
	"fmt"

	k8sApiv1 "k8s.io/api/core/v1"
	meta_v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// ListSecretsFunc is a function that lists secrets given a set of options
type ListSecretsFunc func(meta_v1.ListOptions) (*k8sApiv1.SecretList, error)

// SecretExists determines if a secret exists in the given namespace
func SecretExists(secretName string, listFunc ListSecretsFunc) (bool, error) {
	secrets, err := listFunc(meta_v1.ListOptions{
		FieldSelector: fmt.Sprintf("metadata.name=%s", secretName),
	})

	if err != nil {
		return false, err
	}

	if len(secrets.Items) == 0 {
		return false, nil
	}

	return true, nil
}
