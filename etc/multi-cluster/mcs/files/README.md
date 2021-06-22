# Multi-cluster deployment for DS on GKE using MCS

This document is a guide to deploy DS on multiple regions on GKE using Googles Multi-cluster Services(MCS).

## Overview
This readme explains how to deploy DS in 2 different regions on GKE, using one cluster in US and one cluster in Europe.
Deploying in more regions and/or in other regions would only require to adapt the provided configuration.

There are 5 major steps to the deployment:
* Prepare 2 clusters, one in US and one in Europe
* Prepare configuration that enables the use of shared secrets across the clusters
* Setup MCS in Google Cloud and enable clusters for use within an shared environ
* Prepare docker and kustomize configure to ensure unique server IDs
* Deploy DS using the provided skaffold profiles  
<br />

## Step 1: Prepare 2 clusters  
#
* Provision 2 clusters with following requirements:
  * in the same VPC
  * create in different regions(example is configured for eu and us)
* Create the same namespace in each cluster for DS (default: prod).
* Workload Identity enabled(for MCS and Secret Agent).  
<br />

## Step 2: Enable the use of shared secrets across the clusters
# 
Deploy secret-agent in each cluster:
```
bin/secret-agent.sh
```
Follow instructions to configure secret-agent to work with Workload Identity: [Instructions](https://github.com/ForgeRock/secret-agent#set-up-cloud-backup-with-gcp-secret-manager)  
<br />

## Step 3: Setup MCS
#

**a. Ensure all required APIs are enabled for MCS**  
```
gcloud services enable gkehub.googleapis.com --project <my-project-id>
gcloud services enable dns.googleapis.com --project <my-project-id>
gcloud services enable trafficdirector.googleapis.com --project <my-project-id>
gcloud services enable cloudresourcemanager.googleapis.com --project <my-project-id>
gcloud services enable multiclusterservicediscovery.googleapis.com --project <my-project-id>
```  
<br />

**b. Enable MCS feature**
```
gcloud alpha container hub multi-cluster-services enable --project <my-project-id>
```  
<br />  

**c. Register clusters to an environ**  

Choose a membership name to uniquely identify the cluster.  Please do not use any symbols, just characters.  These names are also required as part of the fqdn when configuring server identifiers.
```
gcloud container hub memberships register <membershipname> \
    --gke-cluster <zone>/<cluster-name> \
    --enable-workload-identity
```  
<br />  

**d. Grant the required IAM permissions for MCS Importer**  

```
gcloud projects add-iam-policy-binding <my-project-id> \
    --member "serviceAccount:<my-project-id>.svc.id.goog[gke-mcs/gke-mcs-importer]" \    
    --role "roles/compute.networkViewer"
```  
<br />  

**e. Verify MCS is enabled**  

```
gcloud alpha container hub multi-cluster-services describe
```
`NOTE:` Look for `lifecycleState: Enabled` in output  
<br />  

## Step 4: Prepare Deployment  
#  

**1. Configure secret-agent parameters**  
>`NOTE:` Please check values and update to match requirements

In `kustomize/overlay/multi-cluster/multi-cluster-secrets/kustomization.yaml` fill out the following fields:  
1. secretsManagerPrefix: \<prefix name\> # ensures unique secret names in Secret Manager.  
2. secretsManager: GCP
3. gcpProjectID: \<Project ID\>  
<br />  

**2. Configure ServiceExport objects**  

>`NOTE:` Currently these files are configured based on 2 replicas of CTS and IDREPO.  Only change if you want a **larger** number of replicas. 

MCS requires a Kubernetes service that can be exposed externally to other clusters for multi-cluster communication.  

`etc/multi-cluster/mcs/files/<region>-export.yaml` must contain a ServiceExport object where `metadata.name` field must match the DS service name.
<br />   

**3. Configure clusters**  

>`NOTE:` Currently these files are configured based on eu and us regions. These values must match the MCS cluster membership names registered in step 3c.

Change the DS_CLUSTER_TOPOLOGY env var for a different list of regional identifiers.

See `kustomize/overlay/multi-cluster/mcs-<region>/kustomization.yaml`  

```
              env: 
              - name: DS_CLUSTER_TOPOLOGY
                value: "eu,us"
              - name: MCS_ENABLED
                value: "true"
```

The above change needs to be applied to the idrepo and cts patch in both regional kustomization.yaml files.  
<br />

**4. Add Skaffold profiles**  
>`NOTE:` Required step 

Add the following profiles to Skaffold.yaml:  
```
- name: mcs-us
  build:
    artifacts:
    - *DS-CTS
    - *DS-IDREPO
    tagPolicy:
      sha256: { }
  deploy:
    kustomize:
      path: ./kustomize/overlay/multi-cluster/mcs-us
  
- name: mcs-eu
  build:
    artifacts:
    - *DS-CTS
    - *DS-IDREPO
    tagPolicy:
      sha256: { }
  deploy:
    kustomize:
      path: ./kustomize/overlay/multi-cluster/mcs-eu
```  
<br />  

## Step 5: Deploy
#  

**1. Deploy the serviceExport objects**  

The serviceExport object will take around 5 mins to register.  After 5 mins DS will be able to communicate with the other cluster.  
This is a 1 time activity so doesn't need to be repeated for each deployment.  

Deploy to US cluster

```
kubectl apply -f etc/multi-cluster/mcs/files/us-export.yaml -n <namespace>
```  

Deploy to EU cluster

```
kubectl apply -f etc/multi-cluster/mcs/files/eu-export.yaml -n <namespace>
```
<br />

**2. Deploy Skaffold profiles**

Deploy to US:
```
skaffold run --profile mcs-us
```

Deploy to EU:
```
skaffold run --profile mcs-eu
```