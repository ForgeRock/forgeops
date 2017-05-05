#!/usr/bin/env bash
# Convenience shell script to redploy AM. Use this for frequent testing of amster import.
# Leaves the cts,userstore and amster alone - so we get faster restart.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/util.sh"

releases=`helm list --namespace ${DEFAULT_NAMESPACE} -q`

for release in $releases 
do
    helm status $release >/tmp/helmstatus
    grep openam /tmp/helmstatus
    if [ "$?" = 0 ]; then
        helm delete --purge $release
        continue;
    fi
    grep configstore /tmp/helmstatus
    if [ "$?" = 0 ]; then
         helm delete --purge $release
        continue;
    fi
done

kubectl delete pvc data-configstore-0


echo "RE-creating OpenDJ configuration store"
bin/opendj.sh configstore

# Configure boot set to false - because we want this to come up waiting to be configured.
echo helm install -f ${CUSTOM_YAML} --set openam.configureBoot=false ${HELM_REPO}/openam
helm install -f ${CUSTOM_YAML} --set openam.configureBoot=false ${HELM_REPO}/openam


echo "executing amster import"

kubectl exec amster -it ./amster-install.sh
