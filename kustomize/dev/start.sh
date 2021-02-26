#!/usr/bin/env bash
set -e

# TODO: allow the user to set FQDN, namespace, etc

#  Check prereqs
if ! $(kubectl get crd secretagentconfigurations.secret-agent.secrets.forgerock.io &> /dev/null); then
        echo "secret-agent not found. Must install ForgeRock/secret-agent before proceeding"
        missing_prereq=true
fi
if ! $(kubectl get crd directoryservices.directory.forgerock.io &> /dev/null); then
        echo "ds-operator not found. Must install ForgeRock/ds-operator before proceeding"
        missing_prereq=true
fi

if [ "$missing_prereq" = true ] ; then
    echo "Please install any missing prereqs and try again."
    exit 1
fi
echo "******Deploying base, including secrets and DS. This is a one time activity******"
kubectl apply -f dist/base.yaml
kubectl apply -f dist/ds.yaml
echo 
echo "******Waiting for git-server and ds pods to come up. This can take up to 5 mins******"
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/name=git-server --timeout=120s
kubectl rollout status --watch statefulset ds-cts --timeout=300s
kubectl rollout status --watch statefulset ds-idrepo --timeout=300s

echo
echo "******Deploying AM and IDM******"
kubectl apply -f dist/apps.yaml
echo 
echo "******Waiting for AM deployment to become available. This can take up to 5 mins******"
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/name=am --timeout=300s
echo
echo "******Waiting for amster job to complete. This can take up to 2 mins******"
kubectl wait --for=condition=complete job/amster --timeout=300s
echo
echo "Deleting amster"
kubectl delete -f dist/amster.yaml

echo
echo "******Deploying UI******"
kubectl apply -f dist/ui.yaml

echo
echo "******Getting the secrets using bin/print-secrets.sh******"
./bin/print-secrets.sh

echo 
echo "******Dev deployment complete. Your environment should be ready******"

