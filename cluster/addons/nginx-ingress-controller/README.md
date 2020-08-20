# Nginx Ingress Controller deployment

These instructions show you how to deploy Nginx Ingress Controller on either EKS/GKE or AKS.  

You must have deployed a EKS, GKE or AKS cluster and set the kube-context.  

Use the section below to choose which arguments you can set for each Cloud Provider. 

The ```ingress-controller-deploy.sh``` script can be found in the bin folder at the root of forgeops.

## EKS

The ingress controller doesn't require an ip as an argument as the EKS deployment creates a separate Load Balancer  
to the EKS cluster.  For EKS run the script with the -e flag for eks:  
```
./ingress-controller-deploy.sh -e
```  

## GKE

For GKE deployments you have the option to either provide an external IP address previously created or let the Ingress Controller  
generate one dynamically. To locate an existing external IP, look at your GCP console under VPC networks.
See https://console.cloud.google.com/networking/addresses/list


Deploy with IP address provided:
```
./ingress-controller-deploy.sh -g -i <ip-address>
```
Let ingress controller generate IP address
```
./ingress-controller-deploy.sh -g
```

## AKS

The Pulumi AKS deployment creates a static ip in a separate Resource Group to the cluster. You also have the option to either provide the  
ip and resource group created by Pulumi or leave it and let the Ingress Controller generate 1 dynamically. To get the ip and Resource Group  
name from the Pulumi Stack output, run the following commands from within the cluster/pulumi/azure/aks folder with your deployed Pulumi Stack selected.

```
pulumi stack output | grep ipResourceGroupName | awk '{ print $2 }'
pulumi stack output | grep staticIpName | awk '{ print $2 }'
```

Deploy with IP and Resource Group name
```
./ingress-controller-deploy.sh -a -i <ip-address> -r <resource-group-name>
```
Let ingress controller generate IP address
```
./ingress-controller-deploy.sh -a
```

## Other script options
Delete ingress controller deployment:
```
./ingress-controller-deploy.sh -d
```
Get help
```
./ingress-controller-deploy.sh -h
```