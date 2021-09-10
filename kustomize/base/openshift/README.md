# Deploying the ForgeRock Identity Platform in an OpenShift Cluster

OpenShift requires the deployment of a security object that adds required permissions for the service account used by the platform.

The `SecurityContextConstraints` object should be deployed _once_ per cluster e.g:

```
kubectl apply -f kustomize/base/openshift/scc.yaml
```
Once you've deployed the security object, you can deploy the CDK and CDM as per the instructions in the documentation. For example, to deploy CDK:

```
# CDK
./bin/forgeops install -n default -f default.iam.example.com

# CDM
skaffold run -p small -n default --default-repo=my.registry.com
```

## Caveat

Route objects might need to have timeouts, upload limits, and other webserver tuning.
