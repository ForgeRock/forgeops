#!/usr/bin/env bash
# Copies the IDM config from the idm-0 pod to the tmp/ directory
# This provides an analogous script to docker/amster/dump-config.sh

rm -fr tmp
pod="idm-0"

echo "Copying the export to the ./tmp directory"
kubectl cp $pod:/opt/openidm/conf ./tmp

echo "Done"
