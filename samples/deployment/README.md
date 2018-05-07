# Forgeops Deployment

### What is in this sample?
Shell scripts and custom charts that facilitate the deployment of the ForgeRock platform in a product like scenerio using the forgeops project.  All you have to do is run the ```deploy.sh``` script and sit back.  

### Prerequisites
This guide assumes you have access to Kubernetes cluster and you have permissions to do deployments. 
Other requirements are:
 - kubectl is fully functional
 - You have an existing cluster and context
 - Helm is installed (Kubernetes package manager)
 - Ingress is deployed and you can access the cluster endpoint
 - You have to edited the variables in `deploy.sh` to your enviroment
 - You have edited  `size/[cluster-size]/amster.yaml` and modified the sedFilter to your environment. Example follows. 
 
```
global:
  git:
    sedFilter: "-e s/benchmark.example.com/[NAMESPACE].[DOMAIN]/"
```

> **Note:** You can use the `forgeops/bin/gke-up.sh` script to create a new cluster.  
  
### Deployment Sizing

- Under the `size` directory there are sub-directors which contain custom charts for deployments of two sizes.  The `s-cluster` is recommended for upto 1M users whereas the `m-cluster` is recommended for upto 10M users. 

> **Caution:** The sizing done in these samples is for guidance only and while it is a good starting point, you are requried to benchmark and size with your own data and use cases.


- You can also modify resource related properties.  Keeping the default is
recommended otherwise they will change outcome of benchmark significantly.

### HA and Multi-Zone deployments
- If you need HA for a single zone cluster then comment out the *openamReplicaCount* and *replicas* keys in each of the yaml file in the `templates` directory.  Set the value to the desired number but make sure that your node is sized appropiately to support the number.

- If you need HA for multi-zone cluster then comment out the *topologyKey* in each of the yaml files. 

### Usage

The deploy.sh can take command line arguments or you can edit the script itself and change the varaibles at the top.  If you change the variables then all you have to do is to execute 
```
$ ./deploy.sh
```
If you don't want to edit the file and rather provide the varaibles via command line switches then just run the script with the help option as folows
```
$ ./deploy.sh --help
```

The deployment will take anywhere from 3-10 minutes so be patient. For a successful deployment you will get a message saying "Deployment is now ready"

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
