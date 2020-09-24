# Source these values for a mini cluster - useful for small tests

# Change cluster name to a unique name that can include alphanumeric characters and hyphens only.
export NAME="mini"

# cluster-up.sh retrieves the region from the user's gcloud config.  Uncomment below to override:
# export REGION=us-east1

# Available zones vary between regions. If your region doesn't include zones a,b and c then uncomment below to override:
# export NODE_LOCATIONS="$REGION-b,$REGION-c,$REGION-d"
# export ZONE="$REGION-b" # required for cluster master

# The machine types for primary and ds node pools
export MACHINE=e2-standard-2
export DS_MACHINE=e2-standard-2
export CREATE_DS_POOL=false

# Values for creating a static IP
export CREATE_STATIC_IP=false # set to true to create a static IP.
# export STATIC_IP_NAME="" # uncomment to provide a unique name(defaults to cluster name).  Lowercase letters, numbers, hyphens allowed.
export DELETE_STATIC_IP=false # set to true to delete static IP, named above, when running cluster-down.sh