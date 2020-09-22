# Source these values for a medium cluster.

# CLUSTER VALUES
# Change cluster name to a unique name that can include alphanumeric characters and hyphens only.
export NAME=medium
export CLUSTER_LABELS="forgerock.io/cluster=cdm-medium"

# cluster-up.sh retrieves the location from the user's az config.  Uncomment below to override:
# export LOCATION=eastus

# Uncomment to provide different Azure Container Registry name than the default(forgeops)
# export ACR_NAME="" 

# PRIMARY NODE POOL VALUES
export VM_SIZE=Standard_DS4_v2
export NODE_COUNT=6
export MIN=1
export MAX=6

# DS NODE POOL VALUES
export CREATE_DS_POOL=true
export DS_VM_SIZE=Standard_DS4_v2
export DS_NODE_COUNT=6
