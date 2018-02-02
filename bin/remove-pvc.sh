#!/usr/bin/env bash
# Force removal of all PVC
# Dangerous!


# First delete the PVC
# If the storage reclaim mode is 'delete', the associated PV should also be deleted,
# Verified on GKE.
pvclist=`kubectl get pvc -o jsonpath='{.items[*].metadata.name}'`

for pvc in ${pvclist}
do
    echo "kubectl delete pvc $pvc"
    kubectl delete pvc ${pvc}
done
