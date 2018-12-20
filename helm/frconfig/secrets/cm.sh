#!/usr/bin/env bash
# Script to generate a CA cert used by cert manager to issue more certificates.
# The generated ca.key and ca.crt files will get slurped up by helm and used to create a secret for cert-manager.

COMMON_NAME="forgerock.com"

openssl genrsa -out ca.key 2048
# The openssl-with-ca is needed on MacOS to provide the CA cert extension. If you are running on Linux openssl does not need it.
openssl req -x509 -new -nodes -key ca.key -sha256 -subj "/CN=${COMMON_NAME}" -days 1024 -out ca.crt -extensions v3_ca -config openssl-with-ca.cnf

