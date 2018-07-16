#!/usr/bin/env bash
# This removes *all* helm charts in the current namespace and deletes all PVCs / PV in the current namespace
# Use with caution - this deletes all of your data as well...

kcontext=`kubectl config current-context`
NS=`kubectl config view -o jsonpath="{.contexts[?(@.name==\"$kcontext\")].context.namespace}"`

while getopts "N" opt; do
        case ${opt} in
            N)  REMOVE_NS="yes" ;;
            \? ) echo "$0 [-N]  Remove helm charts and delete the namespace" ;;
        esac
done
shift $((OPTIND -1))

if [ $# -eq 1 ];
then 
    NS=$1
fi

NAMESPACE=${NS:-default}


echo "Removing all releases for namespace $NAMESPACE"

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
    kubectl delete pvc --namespace ${NAMESPACE}  ${pvc}
done

kubectl delete job --namespace  ${NAMESPACE} --all

if [ -n "$REMOVE_NS" ]; then
    echo "Deleting namespace $NAMESPACE"
    kubectl delete ns "$NAMESPACE"
fi

# Needed for cloudbuild
exit 0