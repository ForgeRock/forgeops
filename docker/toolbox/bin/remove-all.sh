#!/usr/bin/env bash
# This removes *all* helm charts in the current namespace and delete the PVCs / PV in the current namespace
# Use with caution - this deletes all of your data as well...
#

# Get the namespace context
NS=`kubectl config view | grep namespace | awk  '{print $2}'`
DEFAULT_NAMESPACE=${NS:-default}
export DEFAULT_NAMESPACE

releases=`helm list --namespace ${DEFAULT_NAMESPACE} -q`

for r in ${releases}
do
    echo "Deleting release $r"
    helm delete --purge $r
done


pvclist=`kubectl get pvc -o jsonpath='{.items[*].metadata.name}'`

for pvc in ${pvclist}
do
    echo "Deleting $pvc"
    kubectl delete pvc ${pvc}
done


