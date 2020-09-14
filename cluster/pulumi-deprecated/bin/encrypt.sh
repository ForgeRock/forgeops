#!/usr/bin/env sh 
# Use kms to encrypt a plain text file
# file should be provided without the .enc suffix
# Example:
# bin/encrypt.sh etc/cert-manager.json 

file=$1
key="${2:-cert-manager}"

gcloud kms encrypt \
    --plaintext-file="$file" \
    --ciphertext-file="$file.enc"  \
    --keyring=forgeops-build   \
    --key=$key \
    --location=global

