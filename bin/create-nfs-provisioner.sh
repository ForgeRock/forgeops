#!/usr/bin/env sh
# Deploys the nfs external provisioner chart. This creates a provisioner:
# https://github.com/kubernetes-incubator/external-storage/tree/master/nfs 
# Which dynamically creates NFS volumes. This is useful for things like DS - where
# we want all DS servers to mount a common shared backup volume.
# See https://github.com/IlyaSemenov/nfs-provisioner-chart 

helm repo add nfs-provisioner https://raw.githubusercontent.com/IlyaSemenov/nfs-provisioner-chart/master/repo

# Set the desired volume size. Requests will be allocated out of this total.
STORAGE_SIZE="50Gi"

helm install --name nfs-provisioner --namespace nfs-provisioner \
    --set provisionerVolume.mode=pvc,storageClass=nfs,provisionerVolume.settings.storageSize=${STORAGE_SIZE} \
    nfs-provisioner/nfs-provisioner


