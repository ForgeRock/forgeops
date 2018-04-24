#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file


validateInputArgs() {

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
    echo "--cluster-name    - Name of the cluster to delete. Default is openam."
    echo
    exit 0
  fi

}

validateInputArgs "$@"

export ZONE=us-central1-f
PROJECT=engineering-devops

gcloud container clusters delete $CLUSTER_NAME --zone $ZONE



