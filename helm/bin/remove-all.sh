#!/usr/bin/env bash

helm delete --purge openam
helm delete --purge opendj
helm delete --purge openam-install
helm delete --purge userstore
helm delete --purge configstore
helm delete --purge amster
helm delete --purge openidm
helm delete --purge postgres
helm delete --purge openig
helm delete --purge ctsstore

# Delete the OpenDJ data.
kubectl delete pvc data-configstore-0
kubectl delete pvc data-userstore-0
kubectl delete pvc data-ctsstore-0

