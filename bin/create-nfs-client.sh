#!/usr/bin/env bash
# Create an nfs client provisioner.
# WIP: Update this when the nfs-client-provisioner is published to helm stable

source ../etc/gke-env.cfg 

# This is the IP of our GCP filestore instance.
NFS_SERVER="${NFS_SERVER:-10.149.108.186}"
NFS_PATH="${NFS_PATH:-/export}"
NFS_STORAGE_CLASS="${NFS_STORAGE_CLASS:-nfs-client}"
NFS_RELEASE="${NFS_RELEASE:-nfs-client}"


#  --set serviceAccount.create=true \
#      --set serviceAccount.name="nfs-service" \
#     --set rbac.create=true \


kubectl create namespace "$NFS_RELEASE"
helm delete --purge  "$NFS_RELEASE"
helm install --name  "$NFS_RELEASE" --namespace "$NFS_RELEASE" \
     --set nfs.server="${NFS_SERVER}" \
     --set nfs.path="$NFS_PATH" \
     --set storageClass.provisionerName="${GKE_CLUSTER_NAME}" \
     --set storageClass.name="${NFS_STORAGE_CLASS}" \
     ../helm/nfs-client-provisioner