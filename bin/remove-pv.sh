#!/usr/bin/env bash
# Force removal of all pvs
# Dangerous!


pvlist=`kubectl get pv -o jsonpath='{.items[*].metadata.name}'`

for pv in ${pvlist}
do
    echo "kubectl delete pv $pv"
    kubectl delete pv ${pv}
done
