#!/usr/bin/env bash
# Generate an SSL cert (self-signed) and a secret. Used for an ingress controller.

if [ $# -ne 1 ];
then
    echo "Usage: $0  FQDN"
    echo "Where FQDN is something like login.default.example.com"
    exit 1
fi
hostname=$1


openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=$1"


kubectl create secret tls $1 --key /tmp/tls.key --cert /tmp/tls.crt

