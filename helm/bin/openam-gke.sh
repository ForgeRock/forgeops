#!/usr/bin/env bash
# Example of a larger configuration.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/util.sh"

cp ${HELMDIR}/templates/custom-gke.yaml ${HELMDIR}/custom.yaml

cd $DIR

echo "Creating OpenDJ configuration store"
./opendj.sh configstore

# IOPS scales with storage size, so we allocate a lot for performance.
echo "Creating OpenDJ User store"
./opendj.sh userstore --set numberSampleUsers=100000 --set heapSize=10g,storageSize=60Gi


echo "Creating OpenDJ CTS store"
./opendj.sh ctsstore --set bootstrapScript=/opt/opendj/bootstrap/cts/setup.sh --set heapSize=10g,storageSize=50Gi

cd ${HELMDIR}

echo "Installing amster chart"

helm install --name amster -f custom.yaml amster

# Give amster pod time to start.
sleep 30

# Tail the Amster logs in the background.
kubectl logs amster -f &
PID=$!

waitPodReady amster

echo "Removing the amster installation chart"

# For testing the installation, uncomment this so the script exits before the amster / openam pods are deleted.
# This will allow you to examine the OpenAM install.log, etc.
#exit 0

helm delete --purge amster

kill $PID

echo "Starting openam runtime"

helm install --name openam -f custom.yaml openam-runtime --set heapSize=4g

echo "You will see a Terminated: message from the kubectl logs command. It is OK to ignore this"
echo "Done"
