#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

set -o errexit
set -o pipefail
set -o nounset

CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)

source "${BASH_SOURCE%/*}/../etc/gke-env.cfg"

echo "=> Read the following env variables from config file"
echo "Project Name = $GKE_PROJECT_NAME"
echo "Cluster Name = $GKE_CLUSTER_NAME"
echo "Compute Zone = $GKE_PRIMARY_ZONE"
echo ""
if [ "$CURRENT_PROJECT" != "$GKE_PROJECT_NAME" ]; then
    echo "=> Project mismatch detected. Current project is set to $CURRENT_PROJECT"
    echo "=> Please set project by running 'gcloud config set project $GKE_PROJECT_NAME'"
    exit 1
fi
echo "=> Do you want to delete the above cluster?"
read -p "Continue (y/n)?" choice
case "$choice" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit;;
   * ) echo "Invalid input, Bye!"; exit;;
esac

# This helps to release any IP address
helm delete nginx 

sleep 10 

gcloud container clusters delete $GKE_CLUSTER_NAME --zone $GKE_PRIMARY_ZONE --quiet



