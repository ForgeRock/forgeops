#!/usr/bin/env bash
# Create an nfs client provisioner.
# WIP: Update this when the nfs-client-provisioner is published to helm stable

source ../etc/gke-env.cfg 

# This is the IP of our GCP filestore instance.
NFS_SERVER=10.149.108.186


#  --set serviceAccount.create=true \
#      --set serviceAccount.name="nfs-service" \
#     --set rbac.create=true \


kubectl create namespace nfs-client
helm delete --purge nfs-client
helm install --name nfs-client --namespace nfs-client \
     --set nfs.server="${NFS_SERVER}" \
     --set nfs.path="/export" \
     --set storageClass.provisionerName="$GKE_CLUSTER_NAME" \
     ../helm/nfs-client-provisioner