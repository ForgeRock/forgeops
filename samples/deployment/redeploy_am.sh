#!/bin/bash

NAMESPACE=bench
CLUSTER=m-cluster

helm delete amster-$NAMESPACE --purge
helm delete configstore-$NAMESPACE --purge
helm delete openam-$NAMESPACE --purge

kubectl delete pvc db-configstore-0 backup-configstore-0

#helm install --name userstore-$NAMESPACE -f size/$CLUSTER/userstore.yaml  --namespace=$NAMESPACE forgeops/helm/opendj
helm install --name configstore-$NAMESPACE -f size/$CLUSTER/configstore.yaml  --namespace=$NAMESPACE forgeops/helm/opendj
#helm install --name ctsstore-$NAMESPACE -f size/$CLUSTER/ctsstore.yaml  --namespace=$NAMESPACE forgeops/helm/opendj
helm install --name openam-$NAMESPACE -f size/$CLUSTER/openam.yaml  --namespace=$NAMESPACE forgeops/helm/openam
helm install --name amster-$NAMESPACE -f size/$CLUSTER/amster.yaml  --namespace=$NAMESPACE forgeops/helm/amster

echo "Don't forget to delete openam pod for it to pickup config changes once amster finishes"

