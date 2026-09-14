# Migrate from Kustomize to Helm

If you are running on Kustomize, this document will describe how to migrate to
using Helm. If you are still running on a legacy ForgeOps release branch,
upgrade to `release/7.5-20263006` then follow the steps to migrate to Helm in
[migrate-legacy-to-YYYY](migrate-legacy-to-YYYY.md).

If you deployed with Kustomize on ForgeOps 2025.1.0+, or you have already
migrated your legacy deployment to Kustomize, follow this document to migrate
to using Helm.

## Prepare your ForgeOps env

### Set your SSL secret name

By default, the Helm chart uses the FQDN in the SSL secret name, and the
Kustomize base was generated with a FQDN of identity-platform.domain.local.
Your values.yaml needs to be updated to reflect this. These instructions get
the current value from one of the ingresses, sets it to an ENV var, then uses
that ENV var with `forgeops env` to set it.

Set an env var to your current SSL secret name:
`export SSL_SECRET=$(kubectl get ingress -n my-ns admin-ui -o jsonpath='{.spec.tls[0].secretName}')`

Set that SSL secret name in your env:
`forgeops env -e my-env --ssl-secretname $SSL_SECRET`

### Enable the truststore secret

In Kustomize, the truststore secret is enabled so we need to make sure it's
enabled in Helm. Add the following to the `helm/my-env/values.yaml`.

```
platform:
  truststore:
    secret:
      enabled: true
```

## Prepare your running deployment

A few resources need to be deleted, and these steps do so without causing a
downtime. Once you start deleting resources, you need to complete the process
to avoid pod restart failures.

### Delete conflicting resources

Some resources have formatting conflicts between Kustomize and Helm. We can
delete these, and let Helm recreate them. Once these are deleted, AM pods will
fail to restart until Helm is run.

`kubectl delete -n my-ns configmap am-entrypoint am-init-scripts`

### Delete DS StatefulSets

The DS StatefulSets need to be deleted because there are differences in the
immutable fields between Kustomize and Helm. This process orphans the
pods so they keep running once the StatefulSet is gone.

`kubectl delete sts --cascade=orphan -n my-ns ds-cts ds-idrepo`

## Helm

You must use Helm 3.17.0 or higher. It's recommended to use the latest stable
version of Helm. Also, you need to use the ForgeOps 2026.3.2+ Helm chart.

```
helm upgrade -i identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops \
  --version 2026.3.2 -f helm/my-env/values.yaml \
  --take-ownership --namespace my-ns
```

## Restart DS

If your DS pods did not restart after running the above Helm command, you
should restart them.

`kubectl rollout restart -n my-ns sts ds-cts ds-idrepo`

## Complete

The migration is now complete, and you are no longer using Kustomize for this
deployment. You can verify this by running `helm list -n my-ns`.
