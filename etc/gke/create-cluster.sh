#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Google Container Engine (GKE)
# You must have the gcloud command installed and access to a GCP project.
# See https://cloud.google.com/container-engine/docs/quickstart

validateInputArgs() {
  # Set a default cluster version.
  CLUSTER_NAME=openam

  while [[ $# > 0 ]]
  do
    KEY=$1
    shift

    # Parse arguments
    case $KEY in

      # Usage message
      -h)
        USAGE=yes
        ;;

      # Use a cluster version other than the default GKE version?
      --cluster-version)
        CLUSTER_VERSION="--cluster-version $1"
        shift
        ;;

      # Cluster name (default is openam)
      --cluster-name)
        CLUSTER_NAME=$1
        shift
        ;;

    esac
  done

  if [[ ${USAGE} == yes ]]
  then
    echo
    echo "Options:"
    echo "--cluster-version - Kubernetes version to use for cluster deployment."
    echo "                    By default, this script uses the GKE default but"
    echo "                    sometimes it is useful to use a different version."
    echo "--cluster-name    - Name of the cluster to create. Default is openam."
    echo
    exit 0
  fi

}

validateInputArgs "$@"

# Zone in which to create the cluster.
export ZONE=us-central1-f


# 8 cpus, 30 GB of memory
machine="n1-standard-8"
# 16 cpus, 60 GB,  .80 cents / hour
# machine="n1-standard-16"

echo gcloud container clusters create $CLUSTER_NAME $CLUSTER_VERSION \
  --network "default" --num-nodes 1 \
  --machine-type  ${machine} --zone $ZONE \
  --enable-autoscaling --min-nodes=1 --max-nodes=4 \
  --disk-size 50


gcloud container clusters create $CLUSTER_NAME $CLUSTER_VERSION \
  --network "default" --num-nodes 1 \
  --machine-type  ${machine} --zone $ZONE \
  --enable-autoscaling --min-nodes=1 --max-nodes=4 \
  --disk-size 50


# You can add this if you want to use preemptible nodes. These are very inexpensive, but can be taken down at any time.
# --preemptible \
