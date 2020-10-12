#!/usr/bin/env bash
# Script to create a CDM cluster on AKS. This will create a cluster with
# a default nodepool for the apps, and a ds-pool for the DS nodes.
# The values below can be overridden by copying and sourcing an environment variable script. For example:
# - `cp mini.sh my-cluster.sh`
# - `source my-cluster.sh && ./cluster-up.sh`
#

set -o errexit
set -o pipefail

######### GLOBAL VARS #########
# Get the default region
L=$(az configure -l --query "[?name=='location'].value" -o tsv)
LOCATION=${LOCATION:-$L}

# Get current user
CREATOR="${USER:-unknown}"

# Labels can not contain dots that may be present in the user.name
CREATOR=$(echo $CREATOR | sed 's/\./_/' | tr "[:upper:]" "[:lower:]")

######### CLUSTER VARS #########
# Cluster name.
NAME=${NAME:-small}

# Admin Username.  This is the node OS administrator such as root on Linux
ADMIN_USERNAME=${ADMIN_USERNAME:-"forgerock"}

# Name of container registry used by cluster
ACR_NAME=${ACR_NAME}

# For AKS, use the default kubernetes version.
# If you want a specific cluster version uncomment the line below
#KUBE_VERSION=${KUBE_VERSION:-"1.16.13-gke.1"}
# And add this to the cluster and nodepool commands below:
#    --kubernetes-version ${KUBE_VERSION} \

######### RESOURCE GROUP VARS #########
RES_GROUP_NAME=${RES_GROUP_NAME:-"${NAME}-res-group"}

######### NODE GROUP VARS ########
VM_SIZE=${NODE_VM_SIZE:-"Standard_DS3_v2"}
DS_VM_SIZE=${DS_NODE_VM_SIZE:-"Standard_DS3_v2"}
NODE_OSDISK_SIZE=${NODE_OSDISK_SIZE:-80}

# Primary node count
NODE_COUNT=${NODE_COUNT:-3}

# Labels to add to the default pool
PRIMARY_POOL_LABELS="${CLUSTER_LABELS} frontend=true forgerock.io/role=primary"

# Set to "false" if you do not want to create a seperate pool for ds nodes
CREATE_DS_POOL="${CREATE_DS_POOL:-true}"

# Number of DS nodes
DS_NODE_COUNT=${DS_NODE_COUNT:-3}

DS_POOL_LABELS="${CLUSTER_LABELS} forgerock.io/role=ds"

if [ "$CREATE_DS_POOL" == "false" ]; then
  # If there is no ds node pool we must label the primary node pool to allow
  # ds pods to be scheduled there.
  PRIMARY_POOL_LABELS="${PRIMARY_POOL_LABELS} ${DS_POOL_LABELS}"
fi

# By default we disable autoscaling for CDM. If you wish to use autoscaling, 
# uncomment the following and adjust min/max-count as required:
#AUTOSCALE="--enable-cluster-autoscaler --min-count 1 --max-count 3"

# Check user is signed into Azure
authn=$(az ad signed-in-user show | grep userPrincipalName | awk -F: '{print $2}' | sed 's/,//g')
echo -e "\n\nYou are authenticated and logged into Azure as ${authn}.\n"

# Creating resource group
az group create \
   --name $RES_GROUP_NAME \
   --location $LOCATION

# # Create cluster using CLI
az aks create \
    --resource-group "$RES_GROUP_NAME" \
    --name "$NAME" \
    --admin-username "$ADMIN_USERNAME" \
    --attach-acr "$ACR_NAME" \
    --location "$LOCATION" \
    --node-vm-size "$VM_SIZE" \
    --node-osdisk-size 100 \
    --node-count "$NODE_COUNT" \
    --nodepool-labels $PRIMARY_POOL_LABELS \
    --nodepool-name "prim${NAME}" \
    --nodepool-tags "createdby=${CREATOR}" \
    --tags "createdby=${CREATOR}"  \
    --enable-addons "monitoring" \
    --generate-ssh-keys \
    --network-plugin "azure" \
    --load-balancer-sku "standard" \
    --zones 3 \
    $AUTOSCALE  # Note: Do not quote this variable. It needs to expand

# Create the DS pool. This pool does not autoscale.

if [ "$CREATE_DS_POOL" == "true" ]; then
    az aks nodepool add \
      --cluster-name "$NAME" \
      --name "ds${NAME}" \
      --resource-group "$RES_GROUP_NAME" \
      --node-count "$DS_NODE_COUNT" \
      --node-osdisk-size 100 \
      --node-vm-size "$DS_VM_SIZE" \
      --node-taints "WorkerDedicatedDS=true:NoSchedule" \
      --labels $DS_POOL_LABELS \
      --tags "createdby=${CREATOR}"  \
      --zones 3
fi

# Get cluster credentials and set kube-context
az aks get-credentials --resource-group $RES_GROUP_NAME --name $NAME

# Login to ACR
az acr login --name $ACR_NAME

# This standard sc is the same as "default" and the fast is same as "managed-premium"
kubectl create -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: standard
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Standard_LRS
  kind: managed
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: fast
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
EOF

# Create prod namespace for sample CDM deployment
kubectl create ns prod