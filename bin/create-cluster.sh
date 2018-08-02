#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Google Kubernetes Engine (GKE)
# You must have the gcloud command installed and access to a GCP project.
# See https://cloud.google.com/container-engine/docs/quickstart

. ../etc/gke-env.cfg

GKE_NETWORK_NAME="${GKE_NETWORK_NAME:-default}"
GKE_MONITORING_NS="${GKE_MONITORING_NS:-monitoring}"


echo "=> Read the following env variables from config file"
echo "Project Name = $GKE_PROJECT_NAME"
echo "Primary Zone = $GKE_PRIMARY_ZONE"
echo "Additional Zones = $GKE_NODE_LOCATIONS"
echo "Cluster Name = $GKE_CLUSTER_NAME"
echo "Cluster Namespace = $GKE_CLUSTER_NS"
echo "Cluster Monitoring Namespace = $GKE_MONITORING_NS"
echo "Cluster Version = $GKE_CLUSTER_VERSION"
echo "Cluster Size =  $GKE_CLUSTER_SIZE"
echo "VM Type = $GKE_MACHINE_TYPE"
echo "Network = $GKE_NETWORK_NAME"
echo "Ingress Controller IP = $GKE_INGRESS_IP"
echo ""
echo "=> Do you want to continue creating the cluster with these settings?"
read -p "Continue (y/n)?" choice
case "$choice" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit 1;;
   * ) echo "Invalid input, Bye!"; exit 1;;
esac


echo ""
echo "=> Creating cluster called \"$GKE_CLUSTER_NAME\" with specs \"$GKE_MACHINE_TYPE\""
echo ""

MAX_NODES=`expr $GKE_CLUSTER_SIZE + 3`

OPTS=""

if [ ! -z "$GKE_OPTIONS" ]; then 
      OPTS="${GKE_OPTIONS}"
fi

if [ ! -z "$GKE_NODE_LOCATIONS" ]; then 
      OPTS="$OPTS --node-locations=$GKE_NODE_LOCATIONS"
fi

# scopes are required for gcs storage backup and cloud sql

# stackdriver beta is not really stable right now.
#       --enable-stackdriver-kubernetes \


# Create cluster with values parsed from cfg file
gcloud container clusters create $GKE_CLUSTER_NAME \
      --project="$GKE_PROJECT_NAME" \
      --zone="$GKE_PRIMARY_ZONE" \
      --cluster-version="$GKE_CLUSTER_VERSION" \
      --machine-type="$GKE_MACHINE_TYPE" \
      --min-cpu-platform="Intel Skylake" \
      --image-type=COS \
      --disk-size=80 \
      --network="$GKE_NETWORK_NAME" \
      --enable-ip-alias \
      --num-nodes=$GKE_CLUSTER_SIZE \
      --min-nodes=0 \
      --max-nodes=$MAX_NODES \
      --labels="owner=sre" \
      --addons=HorizontalPodAutoscaling \
      --enable-autoscaling \
      --enable-autoupgrade \
      --enable-autorepair \
      --scopes "gke-default" \
      --enable-cloud-logging \
      --enable-cloud-monitoring \
      --disk-type=pd-ssd $OPTS

# --scopes "https://www.googleapis.com/auth/cloud-platform"

#    --enable-cloud-logging --enable-cloud-monitoring \
# These options are no longer required or default:
#       --enable-cloud-monitoring \
#       --username="admin" \
#       --addons=KubernetesDashboard \
#      --enable-cloud-logging \
#      --preemptible
#	 --disk-type=pd-ssd
