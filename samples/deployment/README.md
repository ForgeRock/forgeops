# Forgeops Deployment

### Prerequisites
This guide assumes you have access to Kubernetes cluster and you are able to
do deployments. Other requirements are:
 - You have a namespace
 - Helm is installed (Kubernetes package manager)
 - Ingress is deployed and you can access cluster endpoint

> You can achive all of the above by running the forgeops/bin/gke-up.sh scipt.

#### Deployment Sizing

In `size[cluster-size]/amster.yaml`, you need to modify sedFilter
to match your enviroment. Example follows.

```
global:
  git:
    sedFilter: "-e s/benchmark.example.com/[NAMESPACE].[DOMAIN]/"
```

You can also modify resource related properties.  Keeping the default is
recommended otherwise they will change outcome of benchmark significantly.

### Notes
Its normal to see these Errors repated 4 or 5 times in the begining of the deployment
```
Error from server (BadRequest): container "amster" in pod "amster-77f5c5c778-m7rxx" is waiting to start: PodInitializing
Configuration not finished yet. Waiting for 10 seconds....
```
If you continue to see a lot of these then check the pod by running
```
kubectl describe pod amster-77f5c5c778-m7rxx
```