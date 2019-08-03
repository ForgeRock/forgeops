#!/usr/bin/env bash
# Script to generate a CA cert used by cert manager to issue more certificates.
# The generated ca.key and ca.crt files are used to create a CA secret for cert-manager.

COMMON_NAME="forgerock.com"
SUBDOMAIN="iam"
DOMAIN="example.com"

openssl genrsa -out ca.key 2048
# The openssl-with-ca is needed on MacOS to provide the CA cert extension. If you are running on Linux openssl does not need it.
openssl req -x509 -new -nodes -key ca.key -sha256 -subj "/CN=${COMMON_NAME}" -days 3650 -out ca.crt -extensions v3_ca -config openssl-with-ca.cnf

# Create certificate key
openssl genrsa -out tls.key 2048

# Create certificate signing request 
openssl req -new -sha256 -key tls.key -subj "/C=US/ST=WA/O=ForgeRock/CN=*.${SUBDOMAIN}.${DOMAIN}" -out tls.csr

# Sign the csr and generate crt
openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt -days 1825 -sha256
