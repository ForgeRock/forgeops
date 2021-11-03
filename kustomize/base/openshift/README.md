# Deploying the ForgeRock Identity Platform in an OpenShift Cluster

OpenShift requires the deployment of a security object that adds required permissions for the service account used by the platform. The `SecurityContextConstraints` object should be deployed _once_ per cluster before deploying the ForgeRock Identity Platform.

We provide a sample `SecurityContextConstraints` file required to deploy the platform. However, you must update the SCC with your intended namespace. Find the placeholder service account and replace the placeholder namespace `YOUR-NAMESPACE-HERE` with the namespace you will be using to deploy the platform e.g:

```sh
sed -i 's/YOUR-NAMESPACE-HERE/MY-ACTUAL-NAMESPACE/g' kustomize/base/openshift/scc.yaml
kubectl apply -f kustomize/base/openshift/scc.yaml
```

Once you've deployed the security object, you can deploy the NGINX Ingress Controller, the CDK, and CDM as per the instructions in the documentation. For example:

To deploy the Nginx Ingress controller:

```sh
bin/ingress-controller-deploy.sh --eks  # Use this option for AWS clusters
bin/ingress-controller-deploy.sh --aks  # Use this option for Azure clusters
```

To deploy CDK or CDM:

```sh
# CDK
./bin/forgeops install -n default -f default.iam.example.com

# CDM
./bin/forgeops install -n default --small
```

## Important Notes

1. Route objects might need to have timeouts, upload limits, and other webserver tuning.
1. Forgeops uses the [open source NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/) implementation.
Use `bin/ingress-controller-deploy.sh` to install the correct version of the operator.
1. The [non open source version of the NGINX Ingress Operator](https://docs.nginx.com/nginx-ingress-controller/intro/overview/) is not supported out of the box. It can be used, but
ingress rules and ingress definitions must be provided by the user. The ingress definitions
[provided in forgeops](/kustomize/base/ingress/ingress.yaml) are not compatible with this
operator.
1. `secret-agent` version >= v1.1.4  is required for openShift clusters.
1. `ds-operator` version <= v0.1.0 requires the provided clusterrole patch. e.g:

    ```sh
    bin/ds-operator install
    kubectl apply -f kustomize/base/openshift/ds-operator-role.yaml
    ```

    You must apply this patch _before_ deploying the ForgeRock Identity Platform.
1. You need to provide 2 `storageClass` definitions named "_standard_" and "_fast_".
These storage classes are used to request PVCs for the platform. You can use the storage classes
as defined in `cluster-up.sh` for [azure](/cluster/aks/cluster-up.sh) or [aws](/cluster/eks/cluster-up.sh) as a sample.
