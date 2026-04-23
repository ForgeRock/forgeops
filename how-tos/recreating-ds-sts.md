# How to recreate a DS StatefulSet

## Introduction

There are times when you need to make significant changes to a DS StatefulSet
(sts) which require you to delete the sts. This causes your databases to
disappear. The PVs are still there so you can recreate it and get the hosts and
data back. However, you will suffer a downtime until at least one DS comes back
online.

This document describes how to delete and recreate a DS sts without downtime
when that sts has 2 or more replicas. If you only have 1 DS, then downtime is
unavoidable.

## Steps

In these steps we assume that both the CTS and IDREPO StatefulSets need to be
replaced. You can do it with just one of them as well.

### Delete the sts

The first thing is to delete the sts with the `--cascade=orphan` flag to keep
the pods up and running.

`kubectl delete sts --cascade=orphan -n my-ns ds-cts ds-idrepo`

### Delete the 0 pod

We delete the 0 pod so that it comes up when we deploy the new sts.

`kubectl delete pod -n my-ns ds-cts-0 ds-idrepo-0`

### Deploy new sts

Now you can deploy the change with Helm or Kustomize.

`helm upgrade -i identity-platform ...`

`forgeops apply -e my-env`

### Confirm new 0 pod is up

After doing the deployment, you need to wait until the 0 pod(s) are up and
ready before moving on to the next step.

### Bring up remaining new pods

Now we need to delete the remaining DS pods. We are assuming a 3 pod deployment.

```
kubectl delete pod -n my-ns ds-cts-1 ds-cts-2 ds-idrepo-1 ds-idrepo-2 && \
kubectl rollout restart -n my-ns sts ds-cts ds-idrepo
```

### Confirm new pods are up

Confirm that all DS pods are up and ready.
