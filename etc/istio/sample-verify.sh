#!/usr/bin/env bash
# Installs the istio sample to verify the multi-mesh installation


ISTIO_DIR=~/tmp/istio-1.9.0
export PATH=$ISTIO_DIR/bin:$PATH


istioctl version

# Set these up for your environment
CTX_CLUSTER1=eng
CTX_CLUSTER2=eu


kubectl create --context="${CTX_CLUSTER1}" namespace sample
kubectl create --context="${CTX_CLUSTER2}" namespace sample

kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio-injection=enabled
kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio-injection=enabled

kubectl apply --context="${CTX_CLUSTER1}" \
    -f $ISTIO_DIR/samples/helloworld/helloworld.yaml \
    -l service=helloworld -n sample
kubectl apply --context="${CTX_CLUSTER2}" \
    -f $ISTIO_DIR/samples/helloworld/helloworld.yaml \
    -l service=helloworld -n sample

kubectl apply --context="${CTX_CLUSTER1}" \
    -f $ISTIO_DIR/samples/helloworld/helloworld.yaml \
    -l version=v1 -n sample

kubectl apply --context="${CTX_CLUSTER2}" \
    -f $ISTIO_DIR/samples/helloworld/helloworld.yaml \
    -l version=v2 -n sample

kubectl apply --context="${CTX_CLUSTER1}" \
    -f $ISTIO_DIR/samples/sleep/sleep.yaml -n sample

kubectl apply --context="${CTX_CLUSTER2}" \
    -f $ISTIO_DIR/samples/sleep/sleep.yaml -n sample


# Test with:

kubectl exec --context="${CTX_CLUSTER1}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello

# Run that several times. You should see the request
# bounce back and forth between hello-1 and hello-2.
# You can run that on the other cluster as well:
kubectl exec --context="${CTX_CLUSTER2}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
