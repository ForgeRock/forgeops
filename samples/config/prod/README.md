# Forgeops Production Deployment Sample



### What is in this sample?
Shell scripts and custom helm chart values that facilitate the deployment of the ForgeRock platform in a production-like scenario using (overlaying) the [forgeops](https://github.com/forgerock/forgeops) project.  All you have to do is run the `forgeops/bin/deploy.sh` script as specified below in the [Usage](#Usage) section, sit back and relax.  In a few minutes the whole ForgeRock Platform will be deployed on your Kubernetes cluster in full HA configuration and tuned for high performance.

### Prerequisites
This guide assumes you have access to Kubernetes cluster and appropriate permissions to do deployments.  
Other requirements are:

- `kubectl` is fully functional and latest version
- You have an existing cluster, context and proper permissions/roles
- *Helm* is installed (Kubernetes package manager) with RBAC and tiller is up and running
- *Ingress* is deployed and you can access the cluster endpoint
- You have the `curl` binary installed
- You have modified `*.yaml` files in `samples/config/prod/x-cluster` to cater to your environment



### Choosing the Deployment Size

- The subdirectories contain custom values for "pre-sized" deployments of three categories.  The small `s-cluster` is recommended for up to 1M users, the medium `m-cluster` for up to 10M users and the large `l-cluster` for up to 100M users. 

- Keep in mind that sizing and benchmarking is a very objective exercise and highly depends on the use cases, data, (virtual) hardware and other indirect variables such as cost and networking. In these samples we prescribe the sizing for certain use cases.  This will enable you to ascertain the throughput and latency under these conditions.  Hence the results can be used to size your environment, estimate the cost and benchmark your environment.  

- If you require higher performance, you have also have the choice of horizontal and vertical scaling. Horizontal scaling can be achieved by adding more nodes to the node pool or enabling auto-scaling features of your Kuberntes cluster. Vertical scaling can be achieved by adding higher CPU and Memory nodes to your existing cluster and then re-schedule the pods under stress using any of the available techniques such node selection via resource limits, taints/tolerances. Bear in mind that under certain scenerios even if your user population fits one category, you might still need the next higher category to attain better performance SLA's.

- It is highly recommended to follow the VM sizing guidelines in the table below otherwise your deployment will **most likely fail**. In GKE you should also specify the *Skylake* CPU platform.

    |Cluster Size| vCPU | Memory GB|
    |:----------:|:----:|:--------:|
    |s-cluster   | 4    | 16       |
    |m-cluster   | 16   | 64       |
    |l-cluster   | 32   | 72       |
 
- The cluster should at least have 2 nodes in the primary zone. If HA is desired then either add 2 more nodes to the primary zone or add additional zone(s).  See the HA section below for more details on multi-zone deployment.  The samples are already designed for 2 zone HA.

- Note: You can also use the `forgeops/bin/<provider>-up.sh` script to create a new cluster. For example 
    ```    
    $ bin/gke-up.sh
    ```     

> **Caution:** The sizing done in these samples is for guidance only and while it is a good starting point, you are required to benchmark and size with your own data and use cases.


### HA and Multi-Zone deployments

- These samples are already configured for HA across two zones. Each zones needs minimal of 2 nodes. If you need to add more zones then just create a cluster which more zones in it and ensure the node count is change accordingly. 

- Regional HA is not supported yet by this sample. 


### Usage

- Ensure the value of password fields, domains and namespaces in various yaml files are changed before you deploy.  
 
- The `deploy.sh` script needs to point to a "config" directory.  There are several "config" examples provided under the `forgeops/samples` directory. For example to deploy the medium size (m-cluster) execute 

    ```
    $ ./deploy.sh ../samples/config/prod/m-cluster
    ```

- The deployment will take anywhere from 3-10 minutes so be patient. For a successful deployment you will get a message saying "Deployment is now ready".

- Check out the CDM Cookbook on http://backstage.forgerock.com for more details.

### Notes
- It's normal to see these errors repeated 4 or 5 times in the beginning of the deployment
    ```
    Error from server (BadRequest): container "amster" in pod "amster-XXXXXXXXX-xxxxx" is waiting to start: PodInitializing
    Configuration not finished yet. Waiting for 10 seconds....
    ```
- If you continue to see a lot of these then check the pod by running
    ```
    kubectl describe pod amster-XXXXXXXXX-xxxxx
    ```

