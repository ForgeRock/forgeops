# Source these values for a medium cluster

export NAME="medium"
export REGION=us-east4
# The machine types for primary and ds node pools
export MACHINE=e2-highcpu-16
export DS_MACHINE=c2-standard-16
export PREEMPTIBLE=""
# 2 nodes per zone, total of 6 Primary nodes
export NUM_NODES="2"
# 2 nodes per zone, total of 6 DS nodes
export DS_NUM_NODES="2"