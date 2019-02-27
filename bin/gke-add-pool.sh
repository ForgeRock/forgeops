#!/usr/bin/env bash
#

#set -x

function usage {
	echo "Usage: $0 -l <LABEL> -t <TAINT> -n <POOL_NAME>"
	echo ""
	echo "LABEL		Label for the pool, ex.: type=client"
	echo "TAINT		Taint for the pool, ex.: type=lient:NoSchedule"
	echo "POOL_NAME	Name of the pool, ex.: client-pool-1"
}

while getopts "l:t:n:" args
do
	case "${args}" in
		l)
			LABELS="${OPTARG}"
			;;
		t)
			TAINTS="${OPTARG}"
			;;
		n)
			POOL_NAME="${OPTARG}"
			;;
		*)
			;;
	esac
done    

if [ -z "${LABELS}" ] || [ -z "${TAINTS}" ] || [ -z "${POOL_NAME}" ]
then
	usage
	exit 1
fi

# Load Cluster environment variables
source "${BASH_SOURCE%/*}/../etc/gke-env.cfg"

# Check if running
CLUSTER_STATUS=$(gcloud container clusters list --filter="status:running AND name:${GKE_CLUSTER_NAME}" --format="table[no-heading](status)")

if [[ $CLUSTER_STATUS != "RUNNING" ]]
then
	echo "The cluster ${GKE_CLUSTER_NAME} is not RUNNING but $CLUSTER_STATUS. Quitting"
	exit 1
fi

echo "Pool ${POOL_NAME} with labels ${LABELS} and taints ${TAINTS} will be created on cluster ${CLUSTER_NAME}"

# LIst pools
EXISTING_POOL_NAME=$(gcloud container node-pools list --cluster="${GKE_CLUSTER_NAME}"  --region="${GKE_PRIMARY_ZONE}"  --filter="name:${POOL_NAME}" --format="table[no-heading](name)" )


if [[ ${POOL_NAME} == ${EXISTING_POOL_NAME} ]]
then
	echo "Poll ${POOL_NAME} already exists. Quitting"
	exit 1
fi

# Create the pool
gcloud container node-pools create ${POOL_NAME}  --cluster="${GKE_CLUSTER_NAME}" --region="${GKE_PRIMARY_ZONE}" --node-labels="${LABELS}" --node-taints="${TAINTS}" --num-nodes=1

if (( $? != 0 ))
then
	echo "Adding new pool failed."
	exit 1
fi

# Wait for the reconciling
echo "Please allow the cluster ${CLUSTER_NAME} to reconcile before using the pool. This process can take several minutes."
echo "To monitor reconciliation, run command :"
echo "\$(gcloud container clusters list --filter=\"status:reconciling AND name:${GKE_CLUSTER_NAME}\" --format=\"table[no-heading](status)\""