#!/usr/bin/env bash
# This removes *all* helm charts in the current namespace and deletes all PVCs / PV in the current namespace
# Use with caution - this deletes all of your data as well...

#set -x

kcontext=`kubectl config current-context`
NS=`kubectl config view -o jsonpath="{.contexts[?(@.name==\"$kcontext\")].context.namespace}"`

NAMESPACE=${NS:-default}

# Delete helm charts in specified namespace (of default namespace, if none specified).
# Use --all to make sure charts with DELETED status are removed.
releases=`helm list --namespace ${NAMESPACE} --all -q`

for r in "${releases}"
do
    echo "Deleting release $r"
    helm delete --purge $r
done

# Delete persistent volume claims
pvclist=`kubectl get pvc --namespace ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}'`

for pvc in ${pvclist}
do
    echo "Deleting $pvc"
    kubectl delete pvc ${pvc}
done

