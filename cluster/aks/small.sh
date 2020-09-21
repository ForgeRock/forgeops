# Source these values for a small cluster

# Cluster values
export NAME=small
export CLUSTER_LABELS="forgerock.io/cluster=cdm-small"

# cluster-up.sh retrieves the location from the user's az config.  Uncomment below to override:
# export LOCATION=eastus

# Uncomment to provide different Azure Container Registry name than the default(forgeops)
# export ACR_NAME="" 

# Primary node pool values
export VM_SIZE=Standard_DS3_v2
export NODE_COUNT=3
export MIN=1
export MAX=4

# Primary node pool values
export CREATE_DS_POOL=true
export DS_VM_SIZE=Standard_DS3_v2
export DS_NODE_COUNT=3
