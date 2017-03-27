#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Google Container Engine (GKE)
# You must have the gcloud command installed and access to a GCP project.
# See https://cloud.google.com/container-engine/docs/quickstart

validateInputArgs() {
  CLUSTER_VERSION=""
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
      echo "Cluster name"
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


# Options - we disable GKE HTTP LB addon since we want to deploy the nginx load balancer.
# GCE LB is overkill for a test system.
# Currently we need an alpha cluster to get the StatefulSet feature.
gcloud alpha container clusters create $CLUSTER_NAME $CLUSTER_VERSION \
  --network "default" --num-nodes 2 \
  --enable-kubernetes-alpha \
  --machine-type  n1-standard-2 --zone $ZONE \
  --disable-addons HttpLoadBalancing \
  --enable-autoscaling --min-nodes=2 --max-nodes=4 \
  --disk-size 50

# You can add this if you want to use preemptible nodes. These are very inexpensive, but can be taken down at any time.
# --preemptible \
