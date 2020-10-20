# Source these values for a medium cluster.

# CLUSTER VALUES
# Change cluster name to a unique name that can include alphanumeric characters and hyphens only.
export NAME=medium
export CLUSTER_LABELS="forgerock.io/cluster=cdm-medium"

# cluster-up.sh retrieves the location from the user's az config.  Uncomment below to override:
# export LOCATION=eastus

# Name of Azure Container Registry.  AKS needs to be given access to ACR. Please amend to your registry name.
export ACR_NAME="forgeops" 

# PRIMARY NODE POOL VALUES
export VM_SIZE=Standard_DS5_v2 # vCPU*16, Mem GiB*56, Premium Storage(with caching)
export NODE_COUNT=12

# DS NODE POOL VALUES
export CREATE_DS_POOL=false
# export DS_VM_SIZE=Standard_DS5_v2 # vCPU*16, Mem GiB*56, Premium Storage(with caching)
# export DS_NODE_COUNT=6
