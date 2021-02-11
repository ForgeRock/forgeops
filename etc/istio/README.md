# Istio Multicluster Deployment

These notes cover:

* Installing Istio across two or more Kubernetes clusters

* Deploying Directory Server across the mesh.

If you are only interested in deploying DS, skip to [Deployment](#Deployment).

The sample configures Istio across two existing Kubernetes clusters in the
`us-east1` and `europe-west` regions. The two clusters are on the same Google
Cloud virtual network (VPC).

## References

* [GKE Istio Guide](https://cloud.google.com/solutions/building-multi-cluster-service-mesh-across-gke-clusters-using-istio-single-control-plane-architecture-single-vpc)
* [Istio multi-cluster documentation](https://istio.io/latest/docs/setup/install/multicluster/primary-remote/)

## Set up Istio

1. Change to the `/path/to/forgeops/etc/istio` directory.

1. Run the `firewall.sh` script to open the firewall to let the clusters
   communicate with each other:

    ```
    ./firewall.sh
    ```

1. Download Istio. We used version 1.9.0.

1. Install Istio. After installation, make sure that the `istioctl` command is
   in your path.

1. Set your Kubernetes context to the primary cluster (`eng` in our example).

1. Edit the `install.sh` script for your environment. See the comments in the
   script.

1. Run the `install.sh` script. The script:

    * Creates a sample CA so each cluster trusts the other.

    * Installs Istio on the primary cluster.

    * Creates an east-west gateway that meshes the cluster together.

    * Creates an internal GCP TCP load balancer on the gateway.

    * Installs and configures the remote cluster to use the primary cluster as
      the Istio control plane. Note that the IP address assigned to the load
      balancer is used to create the Operator install script for the remote
      cluster.

1. Edit and run the `sample-verify.sh` script to validate the mesh installation.

## Deploy DS

Deploy the Directory Server in each cluster *in the same namespace* (Important!)

1. Create namespaces *with the same name* in the primary and remote clusters.
   For example:

    ```
    kubectl --context=eng create ns test
    kubectl --context=eu create ns test
    ```

1. Label your namespaces as follows:

    ```
    kubectl --context=eng label ns test istio-injection=enabled --overwrite
    kubectl --context=eu label ns test istio-injection=enabled --overwrite
    ```

    Istio injects the envoy proxy into your deployments only if you label your
    namespace this way.

1. Deploy DS. For example:

    ```
    # Deploy a ds-idrepo instance in the primary cluster using the ds-operator
    kubectl --context=eng --namespace=test apply -f forgeops/kustomize/base/ds-idrepo/ds-idrepo.yaml

    # Deploy a ds-idrepo instance in the remote cluster using the ds-operator
    kubectl --context=eu --namespace=test apply -f forgeops/kustomize/base/ds-idrepo/ds-idrepo.yaml
    ```

1. Create service entries used by Istio to create cross-namespace DNS names:

    ```
    # Primary cluster
    ./create-svc.sh us
    # In the primary cluster, in the test namespace
    kubectl --context=eng --namespace=test apply -f ds-idrepo-svc.yaml

    # Remote cluster
    ./create-svc.sh eu
    # In the remote cluster, in the test namespace
    kubectl --context=eu --namespace=test apply -f ds-idrepo-svc.yaml
    ```

    This script is a temporary measure. The `ds-operator` will eventually
    generate these service names. The script creates service names for pods
    0, 1, and 2 in each region. Even if you have only two pods per region, you
    can still create 3 service names. The third just won't match a pod.

## Verify the Installation

Use the `dsutil` pod to run LDAP tools to query the service names. For example:

```
kubectl run -i --tty dsutil --image=gcr.io/forgeops-public/ds-util -- bash

H=ds-idrepo-0-eu
PW="password from bin/print-secrets.sh"

ldapsearch -h $H -p 1389 -D uid=admin -w $PW --baseDn ou=identities '(objectclass=*)'
```

## TODO

The next step is to configure replication across the mesh USING THE SERVICE
NAMES ABOVE. For example, `ds-idrepo-0-eu` targets the `ds-idrepo-0` pod in
Europe, while `ds-idrepo-0-us` targets the `ds-idrepo-0` pod in the US.

Those service names are unique across the cluster. The DS entrypoint will need
to be augmented to add those servers as seed servers, and to use a region code
to distinguish the server ID.

There are some additional "tweaks" that may or may not need to be applied in
`ds-istio-tweaks.yamal`. These are concerned with mTLS for mesh communication.
The setting defaults to permissive - which allows non TLS communication.