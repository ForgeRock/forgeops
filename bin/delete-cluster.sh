#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file


. ../etc/gke-env.cfg

echo "=> Read the following env variables from config file"
echo "Cluster Name = $GKE_CLUSTER_NAME"
echo "Compute Zone = $GKE_PRIMARY_ZONE"
echo ""
echo "=> Do you want to delete the above cluster?"
read -p "Continue (y/n)?" choice
case "$choice" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit;;
   * ) echo "Invalid input, Bye!"; exit;;
esac

gcloud container clusters delete $GKE_CLUSTER_NAME --zone $GKE_PRIMARY_ZONE



