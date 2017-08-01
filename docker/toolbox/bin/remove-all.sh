#!/usr/bin/env bash
# This removes *all* helm charts in the current namespace and delete the PVCs / PV in the current namespace
# Use with caution - this deletes all of your data as well...

# Only argument is --namespace
NAMESPACE=default
while [[ $# > 0 ]]
do
  KEY=$1
  shift
  case $KEY in
    # Which namespace to delete charts from
    --namespace)
      NAMESPACE=$1
      shift
      ;;
  esac
done

# Delete helm charts in specified namespace (of default namespace, if none specified)
releases=`helm list --namespace ${NAMESPACE} -q`
for r in ${releases}

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


