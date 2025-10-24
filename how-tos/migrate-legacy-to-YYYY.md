# Migrating from legacy ForgeOps to YYYY.x.y

Legacy ForgeOps artifacts were released in individual release branches aligning
with the version of Ping Identity Platform (PIP). These branches were locked to
that specific version of PIP. This caused several problems.

* PIP yearly releases
  * Long wait time for new features
* Backporting headaches
* Difficult to provide supported container images for the platform

In addition to these issues, ForgeOps itself was designed to be a demonstration
instead of a production tool. This led to choices that don't make sense when
managing production deployments. Customers and our Technical Consultants wanted a
tool to help them manage their production deployments. This lead to a rewrite
of the `forgeops` command with a priority on production logistics and
workflows.

This document describes what needs to be done to migrate a legacy deployment
into the new paradigm.

## Migration overview

These instructions have been tested against the `release/7.4-*` and
`release/7.5-*` branches. Earlier branches may or may not work, or need extra
steps. In all cases, test this procedure in a non-production environment before
attempting in production.

The new ForgeOps uses the Helm chart as the source of truth for Kustomize. The
`kustomize/base` is generated from the Helm chart with `bin/base-generate.sh`.
While you can still continue to use Kustomize, we highly recommend using this
opportunity to switch to using Helm.

### If you are using the Helm chart from release/7.4 or release/7.5

If you are using the Helm chart from either the 7.4 or 7.5 release branches,
then you can just upgrade to the latest YYYY.x.z version of the Helm chart. You
should use the `forgeops env` command to create environments for your various
deployments. You can then copy your existing `values.yaml` files into each
environment so that you can use the new tooling to manage your environments
going forward.

## Migration steps

There are a few paths you can take for this migration depending on your needs
and wants. This depends on what your current deployment looks like, and where
you want to end up.

We start with some common steps, and provide alternatives based on what you
want to end up with.

These steps work with any YYYY.x.z release. For this document, we will use
2025.2.1. It is recommended to use the latest version.

### Setup

#### Checkout 2025.2.1

```
cd /path/to/forgeops
git fetch
git switch -c 2025.2.1 2025.2.1
```

#### Create new ENV

In the new ForgeOps, we work with environments on our laptop and then deploy
them. Previously, this was all done at the same time which didn't allow an
admin to look at what is to be deployed before doing it.

Follow the instructions here to migrate your old deployments into a new
environment.

https://docs.pingidentity.com/forgeops/2025.2/upgrade/migrate-forgeops.html

#### Get list of current ReplicaSets

Part of this migration includes deleting Deployments while leaving the pods
orphaned. After the new pods come up, we will terminate the old pods by
deleting the old ReplicaSets that are keeping them around.

```
mkdir /tmp/migrate
kubectl get replicasets -n my-ns -o name > /tmp/migrate/replicasets.txt
```

This command creates a file with the list of replicaset names without any extra
text like headers or status. This is so we can loop over it later to remove the
old replicasets.

#### Prepare the running deployment

##### DS
Delete the DS StatefulSets while orphaning the pods. This keeps the DS pods
running after the StatefulSet is gone.

`kubectl delete sts --cascade=orphan -n my-ns ds-cts ds-idrepo`

We need to delete the `-0` DS pods so new ones come up when we deploy. The PVC
will still be there so your data is safe.

`kubectl delete pod -n my-ns ds-cts-0 ds-idrepo-0`

##### Apps

Delete the am, idm, admin-ui, end-user-ui, and login-ui deployments while
orphaning the pods.

`kubectl delete deployment -n my-ns --cascade=orphan am idm admin-ui end-user-ui login-ui`

##### Jobs

Make sure the amster and ldif-importer jobs are removed, if they aren't already.

`kubectl delete job --ignore-not-found=true -n my-ns amster ldif-importer`

##### Services and Pods

The services and pods need to be modified to align with the new style before we
apply it. Otherwise, services and pods will become disconnected and cause a
service interruption.

First, let's setup some ENV vars for the common items.

```
export COMMON_SELECTORS='app.kubernetes.io/instance=identity-platform,app.kubernetes.io/name=identity-platform,app.kubernetes.io/part-of=identity-platform'
export COMMON_LABELS='app.kubernetes.io/instance=identity-platform app.kubernetes.io/name=identity-platform app.kubernetes.io/part-of=identity-platform'
```

DS-CTS

```
kubectl set selector svc ds-cts -n my-ns "app.kubernetes.io/component=ds-cts,$COMMON_SELECTORS" && \
kubectl label -n my-ns pod -l 'app.kubernetes.io/name=ds-cts' app.kubernetes.io/component=ds-cts $COMMON_LABELS
```

DS-IDREPO

```
kubectl set selector svc ds-idrepo -n my-ns "app.kubernetes.io/component=ds-idrepo,$COMMON_SELECTORS" && \
kubectl label -n my-ns pod --overwrite -l 'app.kubernetes.io/name=ds-idrepo' app.kubernetes.io/component=ds-idrepo $COMMON_LABELS
```

AM

```
kubectl set selector svc am -n my-ns "app.kubernetes.io/component=am,$COMMON_SELECTORS" && \
kubectl label -n my-ns pod --overwrite -l 'app.kubernetes.io/name=am' app.kubernetes.io/component=am $COMMON_LABELS
```

IDM

```
kubectl set selector svc idm -n my-ns "app.kubernetes.io/component=idm,$COMMON_SELECTORS" && \
kubectl label -n my-ns pod --overwrite -l 'app.kubernetes.io/name=idm' app.kubernetes.io/component=idm $COMMON_LABELS
```

ADMIN-UI

```
kubectl set selector svc admin-ui -n my-ns "app.kubernetes.io/component=admin-ui,$COMMON_SELECTORS" && \
kubectl label -n my-ns pod --overwrite -l 'app.kubernetes.io/name=admin-ui' app.kubernetes.io/component=admin-ui $COMMON_LABELS
```

LOGIN-UI

```
kubectl set selector svc login-ui -n my-ns "app.kubernetes.io/component=login-ui,$COMMON_SELECTORS" && \
kubectl label -n my-ns pod --overwrite -l 'app.kubernetes.io/name=login-ui' app.kubernetes.io/component=login-ui $COMMON_LABELS
```

END-USER-UI

```
kubectl set selector svc end-user-ui -n my-ns "app.kubernetes.io/component=end-user-ui,$COMMON_SELECTORS" && \
kubectl label -n my-ns pod --overwrite -l 'app.kubernetes.io/name=end-user-ui' app.kubernetes.io/component=end-user-ui $COMMON_LABELS
```

#### Helm prep

For users going from legacy Kustomize straight to the new Helm chart, there is
additional prep to do. First, we need to annotate and label resources that we
are not recreating so Helm can manage them.

```
kubectl annotate -n my-ns configmap --all meta.helm.sh/release-name='identity-platform' meta.helm.sh/release-namespace='my-ns'
kubectl label -n my-ns configmap --all app.kubernetes.io/managed-by='Helm'
kubectl annotate -n my-ns service --all meta.helm.sh/release-name='identity-platform' meta.helm.sh/release-namespace='my-ns'
kubectl label -n my-ns service --all app.kubernetes.io/managed-by='Helm'
kubectl annotate -n my-ns sac --all meta.helm.sh/release-name='identity-platform' meta.helm.sh/release-namespace='my-ns'
kubectl label -n my-ns sac --all app.kubernetes.io/managed-by='Helm'
```

Next we need to make sure the values.yaml for your environment matches the
settings you brought over from your legacy Kustomize overlay. We'll use the
`--no-kustomize` flag in `forgeops env` to avoid modifying your Kustomize
overlay.

If you followed the instructions above, you should have used `--small`,
`--medium`, or `--large` when creating your environment with `forgeops env`. If
so, then that added the config lines to `helm/my_env/values.yaml`. You can
compare the settings there to what's in `kustomize/overlay/my_env`, and make
them the same. Things like replica count, cpu, mem, and disk.

If you didn't use `--size` when creating your env, then we can do it now to get
those config lines into your `values.yaml`.

`forgeops env -e my_env --small --no-kustomize`

Now the config lines will be in `helm/my_env/values.yaml`, and you can make
them consistent with your Kustomize overlay.

We also need to make sure that the images defined in `image-defaulter` are
present in `values.yaml`. We can use the `forgeops image` command to set a
specific image and tag. First we want to use the image command to select the
upstream images. In this case, our running deployment is on `7.5.0`, so we'll
select that to start. This sets the all images to the correct release before
setting your custom images.

`forgeops image -e my_env --release 7.5.0 platform --no-kustomize`

Now we need to set your custom images. For example, let's say my am image lines
look like this in
`kustomize/overlay/my_env/image-defaulter/kustomization.yaml`:

```
- name: am
-   newName: us-docker.pkg.dev/MyProject/images/am
-     newTag: 7.5.0
```

We can set this in `values.yaml` like so:

`forgeops image --no-kustomize -e my_env --image-repo us-docker.pkg.dev/MyProject/images -t 7.5.0 am`

Do this for any custom image you have built. Now your Helm configuration is ready.

#### Delete unified ingress and deploy new environment

In the new ForgeOps, we have an ingress per component instead of a unified
ingress. To minimize downtime, we will chain the commands together. The
resources are created very quickly so you'll only be without an ingress for a
moment.

##### Helm

```
kubectl delete ingress -n my-ns forgerock ig && \
helm upgrade -i identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops \
  --version 2025.2.1 -f helm/my_env/values.yaml
```

##### Kustomize

```
cd /path/to/forgeops
kubectl delete ingress -n my-ns forgerock ig && \
./bin/forgeops apply -e my_env -n my-ns
```

#### Bring up new DS pods

After deploying the new environment, the `-0` pods should have come up. Once
they are up and ready, then you delete the remaining pods and do a rolling
restart of the DS services to ensure they all come up.

```
kubectl delete pod -n my-ns ds-cts-1 ds-cts-2 ds-idrepo-1 ds-idrepo-2 && \
kubectl rollout restart -n my-ns sts ds-cts ds-idrepo
```

Now deploy the environment with Helm or Kustomize.

#### Ensure new pods are up

After the new DS pods are up, we want to make sure all of the other new pods
have come up. If they don't, deleting them and letting them come back up
usually works.

#### Remove old ReplicaSets

Once all of the new pods are up and ready, we can clean up the old pods. We do
this by deleting the ReplicaSets that we captured in a file above.

`for rs in $(cat /tmp/migrate/replicasets.txt) ; do kubectl delete -n my-ns $rs ; done`
