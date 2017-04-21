#!/usr/bin/env bash
# This removes *all* helm charts in the current namespace and delete the PVCs / PV in the current namespace
# Use with caution - this deletes all of your data as well...
#


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/util.sh"

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


