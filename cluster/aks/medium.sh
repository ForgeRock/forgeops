# Source these values for a medium cluster

# Cluster values
export NAME=medium
export LOCATION=eastus
export CLUSTER_LABELS="forgerock.io/cluster=cdm-medium"
# Uncomment to provide different Azure Container Registry name than the default(forgeops)
# export ACR_NAME="" 

# Primary node pool values
export VM_SIZE=Standard_DS4_v2
export NODE_COUNT=6
export MIN=1
export MAX=6

# Primary node pool values
export CREATE_DS_POOL=true
export DS_VM_SIZE=Standard_DS4_v2
export DS_NODE_COUNT=6
