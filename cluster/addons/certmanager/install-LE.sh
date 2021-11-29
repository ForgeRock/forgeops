#!/usr/bin/env bash
# Install the Let's Encrypt Issuer for Cert-Manager.  Tested on GKE.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Encrypted service account file for LE DNS role
file=$DIR/secrets/cert-manager.json.enc

# decrypt, load as a secret, then delete the plaintext file
gcloud kms decrypt --plaintext-file="-" --ciphertext-file="$file" \
    --keyring=forgeops-build   \
    --key="cert-manager" \
    --location=global  > /tmp/cert-manager.json

kubectl create secret generic clouddns --from-file=/tmp/cert-manager.json -n cert-manager
rm -f /tmp/cert-manager.json

# Create the Let's Encrypt Issuer
kubectl apply -f $DIR/files/le-issuer.yaml
