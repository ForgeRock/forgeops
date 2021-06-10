#!/usr/bin/env bash
# Script to create a CDM cluster on GKE. This will create a cluster with
# a default nodepool for the apps, and a ds-pool for the DS nodes.
# The values below can be overridden by copying and sourcing an environment variable script. For example:
# - `cp mini.sh my-cluster.sh`
# - `source my-cluster.sh && ./cluster-up.sh`
#
set -o errexit
set -o pipefail

# Load regional/project values, they _can_ be used in profiles.
# Default these values from the users configuration
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
PROJECT=${PROJECT:-$PROJECT_ID}

# Get the default region
R=$(gcloud config list --format 'value(compute.region)')
REGION=${REGION:-$R}

#####
# Code for ForgeRock staff only
#####

FO_ENV=${FO_ENV:-env}
# Load and enforce tags
cd "$(dirname "$0")" && . ../../bin/lib-entsec-asset-tag-policy.sh
if [[ -f $HOME/.forgeops.${FO_ENV}.sh ]];
then
    . $HOME/.forgeops.${FO_ENV}.sh
fi
IS_FORGEROCK=$(IsForgeRock)
if [ "$IS_FORGEROCK" == "yes" ];
then
    if ! EnforceEntSecTags;
    then
        echo "ForgeRock staff are required to add specific labels to their"
        echo "Kubernetes clusters. Configure $HOME/.forgeops.${ENV}.sh so that"
        echo "these labels are added to your clusters."
        exit 1
    fi
    ASSET_LABELS="--labels es_zone=${ES_ZONE},es_ownedby=${ES_OWNEDBY},es_managedby=${ES_MANAGEDBY},es_businessunit=${ES_BUSINESSUNIT},es_useremail=${ES_USEREMAIL},billing_entity=${BILLING_ENTITY}"
    ADDITIONAL_OPTS+=" ${ASSET_LABELS} "
fi
#####
# End code for ForgeRock staff only
#####

echo "Deploying to region: $REGION"

if [ -z "$REGION" ]; then
  echo "Please set region in your gcloud config 'gcloud config set compute/region <region>' or in <my-cluster>.sh";
  exit 1
fi

# Where nodes run. We use 3 zones
NODE_LOCATIONS=${NODE_LOCATIONS:-"$REGION-a,$REGION-b,$REGION-c"}
ZONE=${ZONE:-"$REGION-a"}

# The machine types for primary and ds node pools
MACHINE=${MACHINE:-e2-standard-8}
DS_MACHINE=${DS_MACHINE:-n2-standard-8}

# Create a separate node pool for ds
CREATE_DS_POOL="${CREATE_DS_POOL:-false}"

# Get current user
CREATOR="${USER:-unknown}"

# Labels can not contain dots that may be present in the user.name
CREATOR=$(echo $CREATOR | sed 's/\./_/' | tr "[:upper:]" "[:lower:]")

# Labels to add to the default pool
# We need at least one node label to make the command happy
DEFAULT_POOL_LABELS="frontend=true"

if [ "$CREATE_DS_POOL" == "false" ]; then
  # If there is no ds node pool we must label the primary node pool to allow
  # ds pods to be scheduled there.
  DEFAULT_POOL_LABELS="${DEFAULT_POOL_LABELS},forgerock.io/role=ds,forgerock.io/cluster=${NAME}"
fi


NETWORK=${NETWORK:-"projects/$PROJECT/global/networks/default"}
SUB_NETWORK=${SUB_NETWORK:-"projects/$PROJECT/regions/$REGION/subnetworks/default"}

# Create a static IP
CREATE_STATIC_IP="${CREATE_STATIC_IP:-false}"
STATIC_IP_NAME="${STATIC_IP_NAME:-$NAME}"

# Uncomment to use preemptible nodes, or export PREEMPTIBLE="" to override
PREEMPTIBLE=${PREEMPTIBLE:="--preemptible"}

# For GKE we default to use the release channel - where Google selects the kubernetes version and upgrades the cluster
# If you want a specific cluster version uncomment the line below
#KUBE_VERSION=${KUBE_VERSION:-"1.16.13-gke.1"}
# And add this to the first gcloud command:
#    --cluster-version "$KUBE_VERSION" \

# Number of nodes in each zone
NUM_NODES=${NUM_NODES:-"1"} # Primary Node Pool
DS_NUM_NODES=${DS_NUM_NODES:-"1"}

# Release Channel
RELEASE_CHANNEL=${RELEASE_CHANNEL:="regular"}

# Regional Control Plane
HA_CTRL_PLANE=${HA_CTRL_PLANE:=0}
CONTROL_PLANE_OPTS="--zone ${ZONE}"
[[ $HA_CTRL_PLANE -eq 1 ]] && CONTROL_PLANE_OPTS="--region ${REGION}"

# BY default we disable autoscaling for CDM. If you wish to use autoscaling, uncomment the following:
#AUTOSCALE="--enable-autoscaling --min-nodes 0 --max-nodes 3"

# shellcheck disable=SC2086
gcloud beta container --project "$PROJECT" clusters create "$NAME" \
    --node-locations "$NODE_LOCATIONS" \
    --no-enable-basic-auth \
    --no-enable-master-authorized-networks \
    --release-channel "$RELEASE_CHANNEL" \
    --machine-type "$MACHINE" \
    --image-type "COS" \
    --disk-type "pd-ssd" --disk-size "100" \
    --metadata disable-legacy-endpoints=true \
    --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    $PREEMPTIBLE \
    --node-labels "$DEFAULT_POOL_LABELS" \
    --enable-stackdriver-kubernetes \
    --enable-ip-alias \
    --num-nodes "$NUM_NODES" \
    --network "$NETWORK" \
    --subnetwork "$SUB_NETWORK" \
    --default-max-pods-per-node "110" \
    --no-enable-master-authorized-networks \
    --addons HorizontalPodAutoscaling,ConfigConnector,GcePersistentDiskCsiDriver \
    --workload-pool "$PROJECT.svc.id.goog" \
    --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 \
    $CONTROL_PLANE_OPTS \
    $ADDITIONAL_OPTS  # Note: Do not quote this variable. It needs to expand

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
    --node-labels forgerock.io/role=ds,forgerock.io/cluster=${NAME} \
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

# Create the volume snapshot class
kubectl create -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshotClass
metadata:
  name: ds-snapshot-class
driver: pd.csi.storage.gke.io
deletionPolicy: Delete
EOF

# Create prod namespace for sample CDM deployment
kubectl create ns prod

# create the cluster role binding to allow the current user to create new rbac rules.
# Needed for installing addons, istio, etc.
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

# Create static ip if $CREATE_STATIC_IP set to true
if [ "$CREATE_STATIC_IP" == true ]; then
  echo "Creating static IP ${STATIC_IP_NAME}..."
  gcloud compute addresses create "$STATIC_IP_NAME" --project "$PROJECT" --region "$REGION"
  ip=$(gcloud compute addresses describe "$STATIC_IP_NAME" --project "$PROJECT" --region "$REGION" | grep "address:"  | awk '{print $2}')
  echo -e "\nStatic IP: $ip"
  echo -e "\nDon't forget to delete the IP address in the GCP console or when running cluster_down.sh when finished otherwise you will be billed.\n"
fi
