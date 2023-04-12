# Deploying the ForgeRock Identity Platform in an OpenShift Cluster

> This README is a collection of tips intended to point you in the right direction if you're deploying the ForgeRock Identity Platform in an OpenShift cluster.
It should not be considered authoritative deployment documentation. 
Before deploying the platform on OpenShift, please familiarize yourself with ForgeRock's [Statement of Support] for deploying this platform on Kubernetes.

OpenShift requires the deployment of a security object that adds required permissions for the service account used by the platform. The `SecurityContextConstraints` object should be deployed _once_ per cluster before deploying the ForgeRock Identity Platform.

We provide a sample `SecurityContextConstraints` file required to deploy the platform. However, you must update the SCC with your intended namespace. Find the placeholder service account and replace the placeholder namespace `YOUR-NAMESPACE-HERE` with the namespace you will be using to deploy the platform e.g:

```sh
sed -i 's/YOUR-NAMESPACE-HERE/MY-ACTUAL-NAMESPACE/g' kustomize/base/openshift/scc.yaml
kubectl apply -f kustomize/base/openshift/scc.yaml
```

Once you've deployed the security object, follow the steps in the documentation to deploy:

* The NGINX Ingress Controller
* The CDK or the CDM 

## Important Notes

1. Route objects might need to have timeouts, upload limits, and other webserver tuning.
1. Forgeops uses the [open source NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/) implementation.
Use `bin/ingress-controller-deploy.sh` as a model for installing the correct version of the operator.
1. The [non-open source version of the NGINX Ingress Operator](https://docs.nginx.com/nginx-ingress-controller/intro/overview/) is not supported out of the box. It can be used, but
ingress rules and ingress definitions must be provided by the user. The ingress definitions
provided in forgeops are not compatible with this operator.
1. `secret-agent` version >= v1.1.4  is required for OpenShift clusters.
1. `ds-operator` version <= v0.1.0 requires the provided clusterrole patch. e.g:

    ```sh
    bin/ds-operator install
    kubectl apply -f kustomize/base/openshift/ds-operator-role.yaml
    ```

    You must apply this patch _before_ deploying the ForgeRock Identity Platform.
1. You need to provide 2 `storageClass` definitions named `standard` and `fast`.
These storage classes are used to request PVCs for the platform. You can use the storage class
definitions in the Terraform modules in the forgeops-extras repository as examples. 

[About the forgeops repository]:https://ea.forgerock.com/docs/forgeops/forgeops.html
[Authentication rate]:https://ea.forgerock.com/docs/forgeops/how-to/benchmark/authrate.html
[CDK documentation]:https://ea.forgerock.com/docs/forgeops/cdk/overview.html
[CDK Shutdown and Removal]:https://ea.forgerock.com/docs/forgeops/cdk/shutdown.html
[ForgeOps Release Notes]:https://ea.forgerock.com/docs/forgeops/rn/rn.html
[latest release branch]:https://github.com/ForgeRock/forgeops/tree/release/7.3-20230404
[latest release documentation]:https://backstage.forgerock.com/docs/forgeops/7.3/index.html
[Statement of support]:https://backstage.forgerock.com/docs/forgeops/7.3/start/support.html#kubernetes-services
[Troubleshooting]:https://ea.forgerock.com/docs/forgeops/troubleshooting/overview.html
[UI and API access]:https://ea.forgerock.com/docs/forgeops/cdk/access.html