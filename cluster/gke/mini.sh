# Source these values for a mini cluster - useful for small tests

export NAME="mini"

# cluster-up.sh retrieves the region from the user's gcloud config.  Uncomment below to override:
# export REGION=us-east1

# The machine types for primary and ds node pools
export MACHINE=e2-standard-2
export DS_MACHINE=e2-standard-2
export CREATE_DS_POOL=false