# Multi-region deployment for DS on GKE using MCS

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

**1. Ensure all required APIs are enabled for MCS**  
```
gcloud services enable gkehub.googleapis.com --project <my-project-id>
gcloud services enable dns.googleapis.com --project <my-project-id>
gcloud services enable trafficdirector.googleapis.com --project <my-project-id>
gcloud services enable cloudresourcemanager.googleapis.com --project <my-project-id>
gcloud services enable multiclusterservicediscovery.googleapis.com --project <my-project-id>
```  
<br />

**2. Enable MCS feature**
```
gcloud alpha container hub multi-cluster-services enable --project <my-project-id>
```  
<br />  

**3. Register clusters to an environ**  

Choose a membership name to uniquely identify the cluster
```
gcloud container hub memberships register <membership-name> \
    --gke-cluster <zone>/<cluster-name> \
    --enable-workload-identity
```  
<br />  

**4. Grant the required IAM permissions for MCS Importer**  

```
gcloud projects add-iam-policy-binding <my-project-id> \
    --member "serviceAccount:<my-project-id>.svc.id.goog[gke-mcs/gke-mcs-importer]" \    
    --role "roles/compute.networkViewer"
```  
<br />  

**5. Verify MCS is enabled**  

```
gcloud alpha container hub multi-cluster-services describe
```
`NOTE:` Look for `lifecycleState: Enabled` in output  
<br />  

## Step 4: Prepare Deployment  
#  

**1. Configure secret-agent parameters**  
>`NOTE:` Please check values and update to match requirements

In `kustomize/overlay/multi-region/multi-region-secrets/kustomization.yaml` fill out the following fields:  
1. secretsManagerPrefix: \<prefix name\> # ensures unique secret names in Secret Manager.  
2. secretsManager: GCP
3. gcpProjectID: \<Project ID\>  
<br />  

**2. Configure ServiceExport objects**  

>`NOTE:` Currently these files are configured based on 2 replicas of CTS and IDREPO.  Only change if you want a **larger** number of replicas. 

MCS requires a Kubernetes service that can be exposed externally to other clusters for multi cluster communication.  

`etc/multi-region/mcs/files/<region>-export.yaml` must contain a ServiceExport object for each pod in the region.  

The `metadata.name` field must match the replication service name in `kustomize/overlay/multi-region/mcs-<region>/service.yaml`  
<br />  

**3. Configure replication services**  

>`NOTE:` Currently these files are configured based on 2 replicas of CTS and IDREPO.  Only change if you want a **different** number of relicas.  

As mentioned above, a k8s service is required for each DS pod .  
A pod-name selector is required so the service can be mapped directly to a pod .

See `kustomize/overlay/multi-region/mcs-<region>/service.yaml`  

Ensure you have a service per pod  in your topology.  
<br />

**4. Configure regions**  

>`NOTE:` Currently these files are configured based on eu and us regions.  Only change if you want a **different** regional identifies for your DS servers.  

Change the DS_CLUSTER_TOLPOLOGY env var for a different list of regional identifiers.

See `kustomize/overlay/multi-region/mcs-<region>/kustomization.yaml`  

```
              env: 
              - name: DS_CLUSTER_TOPOLOGY
                value: "eu,us"
```

The above change needs to be applied to the idrepo and cts patch in both regional kustomization.yaml files.  
<br />

**5. Update Dockerfile**  
>`NOTE:` Required step.  Temporary until pushed to base DS image.  

In `docker/7.0/ds/cts/Dockerfile` and `docker/7.0/ds/idrepo/Dockerfile`, add/uncomment this line
```
COPY --chown=forgerock:root scripts/docker-entrypoint.sh /opt/opendj
```
<br />  

**6. Add Skaffold profiles**  
>`NOTE:` Required step 

Add the following profiles to Skaffold.yaml:  
```
- name: multi-region-ds-us
  build:
    artifacts:
    - *DS-CTS
    - *DS-IDREPO
    tagPolicy:
      sha256: { }
  deploy:
    kustomize:
      path: ./kustomize/overlay/multi-region/mcs-us
  
- name: multi-region-ds-eu
  build:
    artifacts:
    - *DS-CTS
    - *DS-IDREPO
    tagPolicy:
      sha256: { }
  deploy:
    kustomize:
      path: ./kustomize/overlay/multi-region/mcs-eu
```  
`TODO`: This should be slimmed down once the region is handled differently  
<br />  

## Step 5: Deploy
#  

**1. Deploy the serviceExport objects**  

The serviceExport object will take around 5 mins to register.  After 5 mins DS will be able to communicate with the other cluster.  
This is a 1 time activity so doesn't need to be repeated for each deployment.  

Deploy to US cluster

```
kubectl apply -f etc/multi-region/mcs/files/us-export.yaml -n <namespace>
```  

Deploy to EU cluster

```
kubectl apply -f etc/multi-region/mcs/files/eu-export.yaml -n <namespace>
```
<br />

**2. Deploy Skaffold profiles**

Deploy to US:
```
skaffold run --profile multi-region-ds-us
```

Deploy to EU:
```
skaffold run --profile multi-region-ds-eu
```