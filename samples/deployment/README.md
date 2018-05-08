# Forgeops Deployment

### Prerequisites
This guide assumes you have access to Kubernetes cluster and you have permissions to do deployments. 
Other requirements are:
 - kubectl is fully functional
 - You have an existing cluster
 - You have an existing namespace
 - Helm is installed (Kubernetes package manager)
 - Ingress is deployed and you can access cluster endpoint
 - You have to edited the variables in `deploy.sh` to your enviroment.
 - You have edited  `size/[cluster-size]/amster.yaml` and modified the sedFilter to your environment. Example follows. 
 
```
global:
  git:
    sedFilter: "-e s/benchmark.example.com/[NAMESPACE].[DOMAIN]/"
```

> **Note:** You can use the `forgeops/bin/gke-up.sh` script to create a new cluster.  
  
### Deployment Sizing

- Under the `size` directory there are sub-directors which contain custom templates for deployments of two sizes.  The `s-cluster` is recommended for upto 1M users whereas the `m-cluster` is recommended for upto 10M users. 

**The sizing done in these samples is for guidance only.  You are requried to test and benchmark on your own with your own data and use cases to determine if the sizing provided will be sufficiant for your needs.**


- You can also modify resource related properties.  Keeping the default is
recommended otherwise they will change outcome of benchmark significantly.

### HA and Multi-Zone deployments
- If you need HA for a single zone cluster then comment out the *openamReplicaCount* and *replicas* keys in each of the yaml file in the `templates` directory.  Set the value to the desired number but make sure that your node is sized appropiately to support the number.

- If you need HA for multi-zone cluster then comment out the *topologyKey* in each of the yaml files. 

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
