# AWS/EKS configuration

## Infra Configuration
The 'infra' Pulumi program is a prerequisite for deploying an EKS Pulumi program.  

**infra components**:
* VPC creation
* S3 bucket creation
* Bastion host creation

**Stack configuration options**:
* VPC config
    * ```aws-infra:vpcCIDR: <string>```  
    CIDR block for VPC.  
    * ```aws-infra:numOfAzs: <num>```   
    Number of Availability Zones for VPC.   
* Load Balancer config
    * ```aws-infra:highAvailability: <true|false>```  
    Required for creating an external Load Balancer that could potentially handle multiple EKS Clusters.
* Bucket config
    * ```aws-infra:bucketName: <string>```  
    Provide name for S3 bucket.  
* AWS config  
    * ```aws:region: <region>```  
    Sets the AWS region. All resources will use this region. 
* Bastion config
    * ```aws-infra:bastionEnable: <true|false>```  
    Enable a Bastion server.  Currently disabled.
    * ```aws-infra:bastionAmi: <string>```  
    AMI ID for Bastion server.
    * ```aws-infra:bastionInstanceType: <string>```  
    Instance type for Bastion server.
    * ```aws-infra:pubKey: <secret value>```  
    Public key for accessing Bastion server.


## EKS(Cluster) Configuration
The 'EKS' Pulumi program creates an EKS cluster and related components.  This program inherits VPC, S3 Bucket, Bastion host and Load Balancer configuration from infra Pulumi program.

**EKS components**
* EKS Cluster
    * Node Pools
    * Storage Classes
    * Namespaces

**Stack configuration options**:
* Cluster config
    * ```eks:k8sDashboard: <true|false>```  
    Enable the Kubernetes dashboard. Set to false.  
    * ```eks:k8sVersion: <num>``` *[required]*    
    Kubernetes version.  
    * ```eks:pubKey: <secret string>``` *[required]*   
    Public key to access Cluster nodes.
* Node Pool config
    * ```<nodepool>:ami: <string>```  
    AMI ID of Node Pool VM image.
    * ```<nodepool>:diskSizeGb: <num>```  
    Boot disk size (GB)
    * ```<nodepool>:enable: <true|false>```  *[required]*  
    Enable Node Pool
    * ```<nodepool>:instanceType: <string>```  
    Instance type for Node Pool.
    * ```<nodepool>:maxNodes: <num>```  
    Max nodes per AZ for node pool.
    * ```<nodepool>:minNodes: <num>```  
    Min nodes per AZ for node pool.
    * ```<nodepool>:nodeCount: <num>```  
    Desired node count per availability zone.
* AWS config  
    ```aws:region: <string>```  
    Sets the AWS region. All resources will use this region.



