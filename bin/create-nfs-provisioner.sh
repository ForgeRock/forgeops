#!/usr/bin/env sh
# Deploys the nfs external provisioner chart. This creates a provisioner:
# https://github.com/kubernetes-incubator/external-storage/tree/master/nfs 
# Which dynamically creates NFS volumes. This is useful for things like DS - where
# we want all DS servers to mount a common shared backup volume.
# See https://github.com/IlyaSemenov/nfs-provisioner-chart 

# Set the desired volume size. Requests will be allocated out of this total.
STORAGE_SIZE="100Gi"

echo "Cleaning up any old nfs server deployments"
helm delete --purge nfs-provisioner 
kubectl delete namespace nfs-provisioner
kubectl create namespace nfs-provisioner

helm install --name nfs-provisioner --namespace nfs-provisioner \
    --set provisionerVolume.mode=pvc,storageClass.name=nfs,persistence.size=${STORAGE_SIZE} \
    stable/nfs-server-provisioner


