#!/usr/bin/env sh 
# Use kms to decrypt a file
# file should be provided without the .enc suffix
# Example:
# bin/decrypt.sh etc/cert-manager.json 
key="${2:-cert-manager}"
file=$1

# To list the keys:
#gcloud kms keys list --keyring=forgeops-build --location=global

gcloud kms decrypt --plaintext-file="-" --ciphertext-file="$file.enc"  \
    --keyring=forgeops-build   \
    --key=$key \
    --location=global

