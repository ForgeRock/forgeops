#!/usr/bin/env bash
# Deploy AM. You can use the cmp-am-* composite charts to deploy all the AM components.
# This script is useful for development of the underlying charts.
# Pass any additional helm args on the command line. e.g. -f custom.yaml


# Set this to forgerock to run against the online chart repo.
REPO=.

set -x

helm install $@ ${REPO}/git

echo "Creating OpenDJ configuration store"
helm install $@ --name config --set djInstance=configstore ${REPO}/opendj
#
#echo "Creating OpenDJ user store"
#helm install $@ --set djInstance=userstore --set numberSampleUsers=1000 ${REPO}/opendj

# For casual testing we do not need the CTS
#echo "Creating OpenDJ CTS store"
#helm install $@ --set djInstance=ctsstore ${REPO}/opendj

echo "Installing amster chart"

helm install --name amster $@ ${REPO}/amster

echo "Starting openam"
helm install --name am $@ ${REPO}/openam

echo "Done"
