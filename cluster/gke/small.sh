# Source these values for a small cluster

# Change cluster name to a unique name that can include alphanumeric characters and hyphens only.
export NAME="small"

# cluster-up.sh retrieves the region from the user's gcloud config.  Uncomment below to override:
# export REGION=us-east1

# Available zones vary between regions. If your region doesn't include zones a,b and c then uncomment below to override:
# export NODE_LOCATIONS="$REGION-a,$REGION-b,$REGION-c"

# The machine types for primary and ds node pools
export MACHINE=e2-standard-8
export DS_MACHINE=n2-standard-8
export PREEMPTIBLE=""
