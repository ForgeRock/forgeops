#!/usr/bin/env bash
# This removes *all* helm charts and delete the PVCs

releases=`helm list -q`

for r in ${releases}
do
    echo "Deleting release $r"
    helm delete --purge $r
done


# Delete the OpenDJ data.
kubectl delete pvc data-configstore-0
kubectl delete pvc data-userstore-0
kubectl delete pvc data-ctsstore-0

