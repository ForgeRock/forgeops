package amsecrets

import (
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"

	secretmanager "cloud.google.com/go/secretmanager/apiv1beta1"
	"github.com/pkg/errors"
	log "github.com/sirupsen/logrus"
	"google.golang.org/api/iterator"
	secretmanagerpb "google.golang.org/genproto/googleapis/cloud/secretmanager/v1beta1"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

var amSecretFiles = map[string][]string{
	"openam-keys": {
		"openam/secrets/.keypass",
		"openam/secrets/.storepass",
		"openam/secrets/authorized_keys",
		"openam/secrets/keypass",
		"openam/secrets/keystore.jceks",
		"openam/secrets/keystore.jks",
		"openam/secrets/storepass",
	},
	"openam-keystore-passwords": {
		"openam/secrets/.keypass",
		"openam/secrets/.storepass",
		"openam/secrets/keypass",
		"openam/secrets/storepass",
	},
}

// PlaceOpenAMSecrets retrieves secrets using secretsmanager and
//   puts them in place for use by helm charts
// TODO decide how to only retrieve if the files don't exist
func PlaceOpenAMSecrets(chartsPath, projectID, region string) error {
	ctx := context.Background()
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		return errors.WithStack(err)
	}
	defer client.Close()

	for secretName, files := range amSecretFiles {
		for _, file := range files {
			sanitizedKey := sanitizeKeyName(file)
			name := fmt.Sprintf("projects/%s/secrets/%s_%s/versions/latest", projectID, secretName, sanitizedKey)
			request := &secretmanagerpb.AccessSecretVersionRequest{Name: name}
			secretResponse, err := client.AccessSecretVersion(ctx, request)
			if err != nil {
				return errors.Wrapf(err, "error retrieving secret: %s", name)
			}
			contents := []byte(secretResponse.GetPayload().GetData())
			err = ioutil.WriteFile(fmt.Sprintf("%s/%s", chartsPath, file), contents, 0644)
			if err != nil {
				return errors.WithStack(err)
			}
		}
	}

	return nil
}

// EnsureOpenAMSecrets checks if secrets exist in Cloud Storage, and
//   and if not generates them and sets them via secretsmanager
func EnsureOpenAMSecrets(projectID, region, password string) error {
	ctx := context.Background()
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		return errors.WithStack(err)
	}
	defer client.Close()

	listRequest := &secretmanagerpb.ListSecretsRequest{Parent: fmt.Sprintf("projects/%s", projectID)}
	iteratoR := client.ListSecrets(ctx, listRequest)
	existsCount := 0
	for {
		gcpSecret, err := iteratoR.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil
		}
		gcpSecretName := gcpSecret.GetName()
	k8sSecret:
		for k8sSecretName, files := range amSecretFiles {
			for _, file := range files {
				if gcpSecretName == fmt.Sprintf("%s_%s", k8sSecretName, sanitizeKeyName(file)) {
					existsCount++
					break k8sSecret
				}
			}
		}
	}
	if existsCount == countSecrets(amSecretFiles) {
		return nil
	}

	secrets, err := generateOpenAMSecrets(password)
	if err != nil {
		return err
	}

	err = setOpenAMSecrets(projectID, region, secrets)
	if err != nil {
		return err
	}

	return nil
}

func generateOpenAMSecrets(password string) (map[string][]byte, error) {
	secrets := map[string][]byte{}
	// "DSAME_USER_PWD=foobar ./gen-fraas.sh /tmp"
	cmd := exec.Command("/amSecrets/gen-fraas.sh", "/tmp")
	cmd.Dir = "/amSecrets"
	cmd.Env = append(os.Environ(), fmt.Sprintf("DSAME_USER_PWD=%s", password))
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		log.Error(string(stdoutStderr))
		return secrets, errors.WithStack(err)
	}
	for _, files := range amSecretFiles {
		for _, file := range files {
			data, err := ioutil.ReadFile(fmt.Sprintf("/tmp/%s", file))
			if err != nil {
				return secrets, errors.WithStack(err)
			}
			secrets[file] = data
		}
	}

	return secrets, nil
}

func setOpenAMSecrets(projectID, region string, secrets map[string][]byte) error {
	ctx := context.Background()
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		return errors.WithStack(err)
	}
	defer client.Close()

	for k8sSecretName, files := range amSecretFiles {
		for _, file := range files {
			for key, value := range secrets {
				if key == file {
					sanitizedKey := sanitizeKeyName(file)
					name := fmt.Sprintf("projects/%s/secrets/%s_%s", projectID, k8sSecretName, sanitizedKey)
					getRequest := &secretmanagerpb.GetSecretRequest{Name: name}
					_, err := client.GetSecret(ctx, getRequest)
					if err != nil {
						stat := status.Convert(err)
						if stat.Code() != codes.NotFound {
							return errors.WithStack(err)
						}
						// create
						createRequest := &secretmanagerpb.CreateSecretRequest{
							Parent:   fmt.Sprintf("projects/%s", projectID),
							SecretId: fmt.Sprintf("%s_%s", k8sSecretName, sanitizeKeyName(file)),
							Secret: &secretmanagerpb.Secret{
								Name: name,
								Replication: &secretmanagerpb.Replication{
									Replication: &secretmanagerpb.Replication_Automatic_{
										Automatic: &secretmanagerpb.Replication_Automatic{},
									},
								},
							},
						}
						_, err = client.CreateSecret(ctx, createRequest)
						if err != nil {
							return errors.WithStack(err)
						}
					}
					secretVersionRequest := &secretmanagerpb.AddSecretVersionRequest{
						Parent:  name,
						Payload: &secretmanagerpb.SecretPayload{Data: value},
					}
					_, err = client.AddSecretVersion(ctx, secretVersionRequest)
					if err != nil {
						return errors.WithStack(err)
					}
					break
				}
			}
		}
	}

	return nil
}

func sanitizeKeyName(name string) string {
	return strings.ReplaceAll(strings.ReplaceAll(name, ".", "_"), "/", "_")
}

func countSecrets(secrets map[string][]string) int {
	count := 0
	for _, k8sSecret := range secrets {
		for range k8sSecret {
			count++
		}
	}

	return count
}
