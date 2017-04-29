#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/util.sh"


echo "Creating OpenDJ configuration store"
bin/opendj.sh configstore

echo "Creating OpenDJ user store"
bin/opendj.sh userstore --set numberSampleUsers=1000

echo "Creating OpenDJ CTS store"
bin/opendj.sh ctsstore --set bootstrapScript=/opt/opendj/bootstrap/cts/setup.sh

echo "Installing amster chart"

helm install -f ${CUSTOM_YAML} ${HELM_REPO}/amster

echo "Starting openam"

# Configure boot set to false - because we want this to come up waiting to be configured.
# See https://bugster.forgerock.org/jira/browse/AME-13657. 
helm install -f ${CUSTOM_YAML} --set openam.configureBoot=false ${HELM_REPO}/openam

echo "Done"
