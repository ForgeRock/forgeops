#!/usr/bin/env bash
# Install multimesh cluster - this must be edited for your environment.
#
# See README.md

ISTIO_DIR=~/tmp/istio-1.9.0
export PATH=$ISTIO_DIR/bin:$PATH

istioctl version

# Set these up for your environment
CTX_CLUSTER1=eng
CTX_CLUSTER2=eu

# Set current context to the primary. This uses the ctx plugin
kubectl ctx $CTX_CLUSTER1

# Load CA certs. This is documented in the GKE guide, but the Istio
# guide omits this step. It is not clear this is actually required.

kubectl --context $CTX_CLUSTER1 create namespace istio-system
kubectl --context $CTX_CLUSTER1 create secret generic cacerts -n istio-system \
  --from-file=${ISTIO_DIR}/samples/certs/ca-cert.pem \
  --from-file=${ISTIO_DIR}/samples/certs/ca-key.pem \
  --from-file=${ISTIO_DIR}/samples/certs/root-cert.pem \
  --from-file=${ISTIO_DIR}/samples/certs/cert-chain.pem
kubectl --context $CTX_CLUSTER2 create namespace istio-system
kubectl --context $CTX_CLUSTER2 create secret generic cacerts -n istio-system \
  --from-file=${ISTIO_DIR}/samples/certs/ca-cert.pem \
  --from-file=${ISTIO_DIR}/samples/certs/ca-key.pem \
  --from-file=${ISTIO_DIR}/samples/certs/root-cert.pem \
  --from-file=${ISTIO_DIR}/samples/certs/cert-chain.pem

# Install the primary cluster
istioctl install --context="${CTX_CLUSTER1}" -f gke.yaml

# This exposes the primary cluster to the remote
kubectl apply --context="${CTX_CLUSTER1}" -f $ISTIO_DIR/samples/multicluster/expose-istiod.yaml

# This creates a secret in the primary cluster that is used to trust the remote
istioctl x create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=remote | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"


echo "Sleeping until internal load balancer IP is assigned"

sleep 60

export DISCOVERY_ADDRESS=$(kubectl \
    --context="${CTX_CLUSTER1}" \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')


echo $DISCOVERY_ADDRESS

# Create the remote Istio operator. It uses the IP address above.

cat <<EOF > remote.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        # Enable basic DNS proxying
        ISTIO_META_DNS_CAPTURE: "true"
        # Enable automatic address allocation, optional
        ISTIO_META_DNS_AUTO_ALLOCATE: "true"
  profile: remote
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: remote
      network: network1
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF

#
# *** NOTE - THIS LOOKS LIKE A BUG IN THE ISTIO INSTALLER***
# The install using only --context fails. It looks like your
# current context needs *also* needs to be set to the remote cluster.

kubectl ctx eu
istioctl install --context="${CTX_CLUSTER2}" -f remote.yaml