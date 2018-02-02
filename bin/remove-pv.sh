#!/usr/bin/env bash
# Force removal of all PV
# Dangerous!


# First delete the PVC
# If the storage reclaim mode is 'delete', the associated PV should also be deleted,
# Verified on GKE.
pvlist=`kubectl get pv -o jsonpath='{.items[*].metadata.name}'`

for pv in ${pvlist}
do
    echo "kubectl delete pvc $pv"
    kubectl delete pv ${pv}
done
