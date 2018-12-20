#!/usr/bin/env bash
# Script to update the service account with image pull secrets.
# This is required so that Docker / Kubernetes can authenticate to pull the ForgeRock images
# from the ForgeRock registry server (or any other private registry).
#
# This works in any Kubernetes environment, including Minikube. If you are using Minikube,
# an alternative to using this script is to perform a docker login to the registry service. This
# needs to be done once, so that the docker daemon can authenticate to the registry.

# Put your env vars in this file, or set them through some other means.
# Note that if you are using bintray.io as your registry, specify your API key,
# not your login password, as $REGISTRY_PASSWORD.
env_settings=~/etc/registry_env

if [ -r $env_settings ]; then
    source $env_settings
fi

if [ -z ${REGISTRY+x} ] || [ -z ${REGISTRY_ID+x} ] ||
   [ -z ${REGISTRY_PASSWORD+x} ] || [ -z ${REGISTRY_EMAIL+x} ]; then
    echo "It looks like you have not set one of the following environment variables:"
    echo " REGISTRY, REGISTRY_ID, REGISTRY_PASSWORD or REGISTRY_EMAIL environment variables"
    exit 1
fi

# Create the image pull secret.
kubectl create secret docker-registry frregistrykey \
        --docker-server="${REGISTRY}" \
        --docker-username="${REGISTRY_ID}" \
        --docker-password="${REGISTRY_PASSWORD}" \
        --docker-email="${REGISTRY_EMAIL}"

# Get the service account.
kubectl get serviceaccounts default -o yaml > /var/tmp/sa.yaml

# Delete resourceVersion line.
sed -e '/resourceVersion/d' -i .bak /var/tmp/sa.yaml

# Append image secret.
cat  <<EOF  >>/var/tmp/sa.yaml
imagePullSecrets:
- name: frregistrykey
EOF

# Reload the service account into Kubernetes.
kubectl replace serviceaccount default -f /var/tmp/sa.yaml

echo "Done"

