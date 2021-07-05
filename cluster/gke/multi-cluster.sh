# Source these values for a small cluster

# Change cluster name to a unique name that can include alphanumeric characters and hyphens only.
export NAME="clouddns-us"

# cluster-up.sh retrieves the region from the user's gcloud config.
# NODE_LOCATIONS refers to the zones to be used by CDM in the region. If your region doesn't include zones a,b or c then uncomment and set the REGION, ZONE and NODE_LOCATIONS appropriately to override:
# export REGION=us-east1
# export NODE_LOCATIONS="$REGION-b,$REGION-c,$REGION-d"
# export ZONE="$REGION-b" # required for cluster master

# PRIMARY NODE POOL VALUES
export MACHINE=e2-standard-8
export PREEMPTIBLE=""

# DS NODE POOL VALUES
export CREATE_DS_POOL=false
export DS_MACHINE=n2-standard-8

# Values for creating a static IP
export CREATE_STATIC_IP=false # set to true to create a static IP.
# export STATIC_IP_NAME="" # uncomment to provide a unique name(defaults to cluster name).  Lowercase letters, numbers, hyphens allowed.
export DELETE_STATIC_IP=false # set to true to delete static IP, named above, when running cluster-down.sh

# CloudDNS domain for multi-cluster
export CLOUD_DNS_DOMAIN=us