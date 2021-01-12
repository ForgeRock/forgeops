#!/usr/bin/env bash

# TODO: allow the user to set FQDN, namespace, etc


echo "Deploying base, including secrets and DS. This is a one time activity"

kustomize build dev-base  | kubectl apply -f -

echo "Will sleep for a while to let ds come up"

sleep 30

echo "Deploying am and idm"


kustomize build  am | kubectl apply -f -
kustomize build  idm | kubectl apply -f -

sleep 20

kustomize build  amster | kubectl apply -f -
echo "Deploying amster which will wait for AM. This can take a long time. BE PATIENT!"

kubectl wait --for=condition=complete job/amster --timeout=300s
echo "Deleting amster"
kustomize build amster | kubectl delete -f -


echo "Getting the secrets using bin/print-secrets.sh"

../../bin/print-secrets.sh


echo "Done"

