#!/usr/bin/env sh 
# Use kms to encrypt a plain text file
# args: file [key-name]

file=$1
key="${2:-cert-manager}"


gcloud kms encrypt \
    --plaintext-file="$outfile" \
    --ciphertext-file="$file"  \
    --keyring=forgeops-build   \
    --key=$key \
    --location=global

