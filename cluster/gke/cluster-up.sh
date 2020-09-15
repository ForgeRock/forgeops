#!/usr/bin/env bash
# Script to create a CDM cluster on GKE. This will create a cluster with
# a default nodepool for the apps, and a ds-pool for the DS nodes.
# The values below create a "small" cluster and
# can be overridden by sourcing an environment variable script.  For example `source mini.sh && ./cluster-up.sh`
#


set -o errexit
set -o pipefail

# Cluster name.
NAME=${NAME:-small}


# Default these values from the users configuration
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
PROJECT=${PROJECT:-$PROJECT_ID}

# Get the default region
R=$(gcloud config list --format 'value(compute.region)')
REGION=${REGION:-$R}

# Where nodes run. We use 3 zones
NODE_LOCATIONS=${NODE_LOCATIONS:-"$REGION-a,$REGION-b,$REGION-c"}
ZONE=${ZONE:-"$REGION-a"}

# The machine types for primary and ds node pools
MACHINE=${MACHINE:-e2-standard-8}
DS_MACHINE=${DS_MACHINE:-n2-standard-8}

# Set to "false" if you do not want to create a separate pool for ds nodes
CREATE_DS_POOL="${CREATE_DS_POOL:-true}"


# Get current user
CREATOR="${USER:-unknown}"


# Labels to add to the default pool
# We need at least one node label to make the command happy
DEFAULT_POOL_LABELS="frontend=true"

if [ "$CREATE_DS_POOL" == "false" ]; then
  # If there is no ds node pool we must label the primary node pool to allow
  # ds pods to be scheduled there.
  DEFAULT_POOL_LABELS="${DEFAULT_POOL_LABELS},forgerock.io/role=ds"
fi


NETWORK=${NETWORK:-"projects/$PROJECT/global/networks/default"}
SUB_NETWORK=${SUB_NETWORK:-"projects/$PROJECT/regions/$REGION/subnetworks/default"}

# Uncomment to use preemptible nodes, or export PREEMPTIBLE="" to override
PREEMPTIBLE=${PREEMPTIBLE:="--preemptible"}

# For GKE we default to use the release channel - where Google selects the kubernetes version and upgrades the cluster
# If you want a specific cluster version uncomment the line below
#KUBE_VERSION=${KUBE_VERSION:-"1.16.13-gke.1"}
# And add this to the first gcloud command:
#    --cluster-version "$KUBE_VERSION" \

# Number of nodes in each zone for DS
DS_NUM_NODES=${DS_NUM_NODES:-"1"}

gcloud beta container --project "$PROJECT" clusters create "$NAME" \
    --zone "$ZONE" \
    --node-locations "$NODE_LOCATIONS" \
    --no-enable-basic-auth \
    --no-enable-master-authorized-networks \
    --release-channel "regular" \
    --machine-type "$MACHINE" \
    --image-type "COS" \
    --disk-type "pd-ssd" --disk-size "100" \
    --metadata disable-legacy-endpoints=true \
    --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    "$PREEMPTIBLE" \
    --node-labels "$DEFAULT_POOL_LABELS" \
    --enable-stackdriver-kubernetes \
    --enable-ip-alias \
    --num-nodes "1" \
    --network "$NETWORK" \
    --subnetwork "$SUB_NETWORK" \
    --default-max-pods-per-node "110" \
    --enable-autoscaling --min-nodes "0" --max-nodes "3" \
    --no-enable-master-authorized-networks \
    --addons HorizontalPodAutoscaling,ConfigConnector \
    --workload-pool "$PROJECT.svc.id.goog" \
    --labels "createdBy=$CREATOR" \
    --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0


# Create the DS pool. This pool does not autoscale.

if [ "$CREATE_DS_POOL" == "true" ]; then
  gcloud beta container --project "$PROJECT" node-pools create "ds-pool" \
    --cluster "$NAME" \
    --zone "$ZONE" \
    --node-locations "$NODE_LOCATIONS" \
    --machine-type "$DS_MACHINE" \
    --image-type "COS" \
    --disk-type "pd-ssd" \
    --disk-size "100" \
    --metadata disable-legacy-endpoints=true \
    --node-labels forgerock.io/role=ds \
    --node-taints WorkerDedicatedDS=true:NoSchedule \
    --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    "$PREEMPTIBLE" \
    --num-nodes "$DS_NUM_NODES" \
    --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0
fi

# Create the fast storageclass needed by DS
kubectl create -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
parameters:
  type: pd-ssd
provisioner: kubernetes.io/gce-pd
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF

# Create prod namespace for sample CDM deployment
kubectl create ns prod

# create the cluster role binding to allow the current user to create new rbac rules.
# Needed for installing addons, istio, etc.
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)