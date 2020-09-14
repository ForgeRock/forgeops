# GCP/GKE configuration

## Infra Configuration
The 'infra' Pulumi program is a prerequisite for deploying a GKE Pulumi program.  

**infra components**:
* VPC creation
* GCP bucket creation

**Stack configuration options**:
* VPC config
    * ```vpc:enable: <true|false>```  
    Create VPC. But if you already have a VPC created outside of Pulumi then you can provide the VPC ID in the 'gke' program.    
    To disable set ```vpc:enable: "false"```.  
    ```NOTE```: currently you'll still need to deploy the infra stack even if you have a VPC already.   
* Bucket config
    * ```bucket:enable: <true|false>```  
    Set to true to create a GCP bucket. Defaults to false.  
    * ```bucket:name: <string>```  
* GCP config  
    * ```gcp:region: <string>```  
    Sets the GCP region. All resources will use this region. 


## GKE(Cluster) Configuration
The 'gke' Pulumi program creates a GKE cluster and related components.  This program inherits VPC and GCP Bucket from infra Pulumi program.

**GKE components**
* GKE Cluster
    * Node Pools
    * Local SSDs
    * Storage Classes
    * Namespaces
* Static IP

**Stack configuration options**:
* Cluster config
    * ```cluster:availabilityZoneCount: <num>``` *[required]*   
    How many availability zones(AZs) to deploy GKE nodes across.  
    A Node Pool's ```<nodepoolname>:nodeCount``` value will be multiplied by the number for AZs.
    * ```cluster:k8sVersion: <version>``` *[required]*    
    Kubernetes version.  This is used to work out the full GKE master kubernetes patch version.  
    So provide version 1.15 and it will work out the lastest patch e.g. 1.15.5.
    * ```cluster:name: <name>```  *[required]*   
    Actual name of cluster.
* Node Pool config
    * ```<nodepool>:autoScaling: <true|false>``` *[required for primarynodes only]*  
    Enable autoscaling for each Node Pool.  
    Because DS is currently not scalable, **DS node pool** has autoscaling disabled.   
    **Frontend Node Pool** is only for Ingress Controller so generally doesn't need autoscaling so set to false by default.  
    **Primary Node Pool** contains AM and IDM plus everything else if other Node Pools aren't used. Autoscaling is enabled by default.
    * ```<nodepool>:diskSizeGb: <num>```  
    Boot disk size (GB)
    * ```<nodepool>:enable: <true|false>```  *[required]*  
    Enable Node Pool
    * ```<nodepool>:nodeCount: <num>```  
    Desired node count if Autoscaling disabled.  If autoScaling: true, set nodeCount: 0. Defaults to 0.
    * ```<nodepool>:NodeMachineType: <string>```  
    Set machine type for Node Pool. Defaults to n1-standard-2  
    * ```<nodepool>:preemptible <true|false>``` *[required for primarynodes only]*  
    Select preemptible nodes. Default to false if not primarynodepool.  
    * ```<nodepool>:localSsdCount: <num>```  
    Number of localssds if localssdprovisioner config provided as described below.
* GCP config  
    ```gcp:region: <string>```  
    Sets the GCP region. All resources will use this region. 
* Local SSDs  
    ```localssdprovisioner:enable: <true|false>```   
    Enable local SSD provisioner and create local SSDs with the cluster.  
    ```localssdprovisioner:namespace: <string>```  
    Configure namespace for localssdprovisioner.



