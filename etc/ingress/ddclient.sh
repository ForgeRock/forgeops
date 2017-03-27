#!/usr/bin/env bash
# Setup dynamic DNS client.
# Put your DynDNS credentials in ~/etc/dyndns.

source ~/etc/dyndns

sed -e "s/DYNDNS_PASSWORD/${DYNDNS_PASSWORD}/"  -e "s/DYNDNS_LOGIN/${DYNDNS_LOGIN}/"  \
    -e  "s/DYNDNS_HOSTS/${DYNDNS_HOSTS}/" <ddclient-template.yaml >/tmp/ddclient.yaml

kubectl create -f /tmp/ddclient.yaml
