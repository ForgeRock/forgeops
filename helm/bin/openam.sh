#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/util.sh"

cd $DIR

echo "Creating OpenDJ configuration store"
./opendj.sh configstore

echo "Creating OpenDJ user store"
./opendj.sh userstore --set numberSampleUsers=1000

echo "Creating OpenDJ CTS store"
./opendj.sh ctsstore --set bootstrapScript=/opt/opendj/bootstrap/cts/setup.sh

cd ${HELMDIR}

echo "Installing amster chart"

helm install -f custom.yaml amster

# Give amster pod time to start.
sleep 30

# Tail the Amster logs in the background.
kubectl logs amster -f &
PID=$!

waitPodReady amster


# For testing the installation, uncomment this so the script exits before the amster / openam pods are deleted.
# This will allow you to examine the OpenAM install.log, etc.
#exit 0


# Find the amster chart
AMSTER_RELEASE=`helm list --namespace ${DEFAULT_NAMESPACE} | grep amster | awk '{print $1}'`

echo "Removing the amster release $AMSTER_RELEASE"

helm delete ${AMSTER_RELEASE}

# Kill the tail process
kill $PID

echo "Starting openam runtime"

helm install -f custom.yaml openam

echo "You will see a Terminated: message from the kubectl logs command. It is OK to ignore this."
echo "Done"
