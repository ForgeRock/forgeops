# AKS setup with Pulumi


## Infrastructure Stack Configuration

Deploys the following:

* cluster resource group
* service principal

### Options

* acrResourceGroupName: resource group that has the ACR registry
* location: eastus
* servicePrincipalSecret

## Cluster Stack Configuration

Deploys the following:

* AKS cluster
* varying number of node worker pools

### Options

* clusterResourceGroupName: resource group for AKS
* k8sVersion: kubernetes version
* numOfAzs: number of availability zones
* sshPublicKey: ssh public key for worker nodes
* environment: AzureCloud
* dsnodes:diskSizeGb: disk size for ds worker nodes
* dsnodes:enable: use dedicated node pools for ds
* dsnodes:enableAutoScaling: enable autoscaling for pool
* dsnodes:instanceType: machine type for pool
* dsnodes:maxNodes: max number for nodes (as a string)
* dsnodes:minNodes: min number for nodes (as a string)
* dsnodes:nodeCount: number for nodes (as a string)
* frontendnodes:diskSizeGb: disk size for ingress worker nodes
* frontendnodes:enable: use dedicated node pools for ingress
* frontendnodes:enableAutoScaling: enable autoscaling for pool
* frontendnodes:instanceType: machine type for pool
* frontendnodes:maxNodes: max number for nodes (as a string)
* frontendnodes:minNodes: min number for nodes (as a string)
* frontendnodes:nodeCount: number for nodes (as a string)
* primarynodes:diskSizeGb: disk size for primary worker nodes
* primarynodes:enable: use dedicated node pools for primary pool
* primarynodes:enableAutoScaling: enable autoscaling for pool
* primarynodes:instanceType: machine type for pool
* primarynodes:maxNodes: max number for nodes (as a string)
* primarynodes:minNodes: min number for nodes (as a string)
* primarynodes:nodeCount: number for nodes (as a string)

