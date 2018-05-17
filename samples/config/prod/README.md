# Forgeops Production Deployment Sample

### What is in this sample?
Shell scripts and custom values that facilitate the deployment of the ForgeRock platform in a production-like scenerio using (overlaying) the forgeops project.  All you have to do is run the `forgeops/bin/deploy.sh` script as specified below in the "Usage" section, sit back and relax.  

### Prerequisites
This guide assumes you have access to Kubernetes cluster as described above and permissions to do deployments.  
Other requirements are:
 - kubectl is fully functional
 - You have an existing cluster and context
 - Helm is installed (Kubernetes package manager)
 - Ingress is deployed and you can access the cluster endpoint
 - You have `curl` binary installed
 - You have modified `*.yaml` files in `samples/config/<directory>` to cater to your environment.


### Choosing the Deployment Size

- The subdirectories contain custom values for deployments of two sizes.  The small `s-cluster` is recommended for upto 1M users whereas the medium `m-cluster` is recommended for upto 10M users. It is highly recommended to have 8 vCPU and 20GB RAM per node for the small cluster and 16vCPU and 40GB RAM per node for the medium cluster. Otherwise the deployment **could fail**. 

- The cluster should atleast have 2 nodes in the primary zone. If HA is desired then either add 2 more nodes to the primary zone or add addtional zone(s).  See the HA section below for more details on multi-zone deployment.

- Note: You can also use the `forgeops/bin/<provider>-up.sh` script to create a new cluster. For example `gke-up.sh` 

> **Caution:** The sizing done in these samples is for guidance only and while it is a good starting point, you are requried to benchmark and size with your own data and use cases.


### HA and Multi-Zone deployments
- If you need HA for a single zone cluster then comment out the *openamReplicaCount* and *replicas* keys in each of the yaml file in the `templates` directory.  Set the value to the desired number but make sure that your node is sized appropiately to support the number.

- If you need HA for multi-zone cluster then comment out the *topologyKey* in each of the yaml files.

- Regional HA is not supported yet by this sample. 


### Usage

The `deploy.sh` script can take command line arguments or a configuration file.  If you choose to use the configuration directory then all you have to do is to execute `./deploy.sh -c <path to config directory>`

Alternatively you can provide the variables in the configuration file via command-line switches . For information about the switches, run the script with the --help option.

The deployment will take anywhere from 3-10 minutes so be patient. For a successful deployment you will get a message saying "Deployment is now ready"


### Notes
It's normal to see these errors repeated 4 or 5 times in the beginning of the deployment
```
Error from server (BadRequest): container "amster" in pod "amster-XXXXXXXXX-xxxxx" is waiting to start: PodInitializing
Configuration not finished yet. Waiting for 10 seconds....
```
If you continue to see a lot of these then check the pod by running
```
kubectl describe pod amster-XXXXXXXXX-xxxxx
```

