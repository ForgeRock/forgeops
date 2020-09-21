# Source these values for a medium cluster

export NAME="small"

# cluster-up.sh retrieves the region from the user's gcloud config.  Uncomment below to override:
# export REGION=us-east1

# The machine types for primary and ds node pools
export MACHINE=e2-standard-8
export DS_MACHINE=n2-standard-8
export PREEMPTIBLE=""
