#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Google Kubernetes Engine (GKE)
# You must have the gcloud command installed and access to a GCP project.
# See https://cloud.google.com/container-engine/docs/quickstart

. ../etc/gke-env.cfg

echo "=> Read the following env variables from config file"
echo "Project Name = $GKE_PROJECT_NAME"
echo "Primary Zone = $GKE_PRIMARY_ZONE"
echo "Additional Zones = $GKE_ADDITIONAL_ZONES"
echo "Cluster Name = $GKE_CLUSTER_NAME"
echo "Cluster Namespace = $GKE_CLUSTER_NS"
echo "Cluster Version = $GKE_CLUSTER_VERSION"
echo "Cluster size =  $GKE_CLUSTER_SIZE"
echo "VM Type = $GKE_MACHINE_TYPE"
echo "Ingress Controller IP = $GKE_INGRESS_IP"
echo ""
echo "=> Do you want to continue creating the cluster with these settings?"
read -p "Continue (y/n)?" choice
case "$choice" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit;;
   * ) echo "Invalid input, Bye!"; exit;;
esac


echo ""
echo "=> Creating cluster called \"$GKE_CLUSTER_NAME\" with specs \"$GKE_MACHINE_TYPE\""
echo ""

gcloud beta container clusters create $GKE_CLUSTER_NAME \
      --project=$GKE_PROJECT_NAME \
      --zone=$GKE_PRIMARY_ZONE \
      --node-locations="$GKE_PRIMARY_ZONE,$GKE_ADDITIONAL_ZONES" \
      --username="admin" \
      --cluster-version=$GKE_CLUSTER_VERSION \
      --machine-type=$GKE_MACHINE_TYPE \
      --min-cpu-platform="Intel Skylake" \
      --image-type=COS \
      --disk-size=50 \
      --network=default \
      --num-nodes=$GKE_CLUSTER_SIZE \
      --min-nodes=0 \
      --max-nodes=$GKE_CLUSTER_SIZE \
      --labels=owner=sre \
      --addons=HorizontalPodAutoscaling \
      --addons=KubernetesDashboard \
      --enable-cloud-logging \
      --enable-cloud-monitoring \
      --enable-autoscaling \
      --enable-autoupgrade \
      --enable-autorepair


#      --preemptible
#	   --disk-type=pd-ssd



exit 0

