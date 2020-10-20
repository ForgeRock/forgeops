# Source these values for a medium cluster

# Change cluster name to a unique name that can include alphanumeric characters and hyphens only.
export NAME="medium"

# cluster-up.sh retrieves the region from the user's gcloud config.
# NODE_LOCATIONS refers to the zones to be used by CDM in the region. If your region doesn't include zones a,b or c then uncomment and set the REGION, ZONE and NODE_LOCATIONS appropriately to override:
export REGION=us-east1
export NODE_LOCATIONS="$REGION-b,$REGION-c,$REGION-d"
export ZONE="$REGION-b" # required for cluster master

# PRIMARY NODE POOL VALUES
export MACHINE=c2-standard-16
# 2 nodes per zone, total of 6 Primary nodes
export NUM_NODES="2"
export PREEMPTIBLE=""

# DS NODE POOL VALUES
export CREATE_DS_POOL=false
# export DS_MACHINE=c2-standard-16
# # 2 nodes per zone, total of 6 DS nodes
# export DS_NUM_NODES="2"

# Values for creating a static IP
export CREATE_STATIC_IP=false # set to true to create a static IP.
# export STATIC_IP_NAME="" # uncomment to provide a unique name(defaults to cluster name).  Lowercase letters, numbers, hyphens allowed.
export DELETE_STATIC_IP=false # set to true to delete static IP, named above, when running cluster-down.sh