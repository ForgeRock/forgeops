# Multi-region deployment for DS on GKE

This document shows you how to deploy DS on multiple regions on GKE.

## Overview
This guide explains how to deploy DS in 2 different regions on GKE, using one cluster in the US and one cluster in Europe.
To deploy in more regions or other regions, adapt the provided configuration.

There are 4 major steps to the deployment:
* Prepare 2 clusters, one in the US and one in Europe
* Enable the use of shared secrets across the clusters
* Deploy DNS load balancers and configure DNS for the clusters
* Deploy DS using the provided Skaffold profiles

## Step 1: Prepare 2 clusters
The clusters must be in the same VPC.
The same namespace will be used in both clusters to deploy DS.

## Step 2: Enable the use of shared secrets across the clusters
Verify that secret agent is installed in both clusters; if it isn't, install it:
```
bin/secret-agent.sh
```
In the Google Cloud Console, verify that:
* There is a service account dedicated to a secret agent (`GSA_NAME@PROJECTID.iam.gserviceaccount.com`); if there isn't, create it (ask cluster manager).  
* The service account for the secret agent has a role usable for workload identity, otherwise add the missing role by running:
```
gcloud iam service-accounts add-iam-policy-binding --role roles/iam.workloadIdentityUser --member "serviceAccount:${PROJECTID}.svc.id.goog[secret-agent-system/secret-agent-manager-service-account]" ${GSA_NAME}@${PROJECTID}.iam.gserviceaccount.com
```

Verify the service account annotations in the secret agent namespace, by making sure that the output of:
```
kubectl -n secret-agent-system get serviceaccounts secret-agent-manager-service-account -o yaml
```
contains the following annotation
```
metadata:
annotations:
iam.gke.io/gcp-service-account: ${GSA_NAME}@{PROJECTID}.iam.gserviceaccount.com
```
Otherwise, execute following command (GSA_NAME and PROJECTID to replace):
```
kubectl -n secret-agent-system annotate serviceaccounts secret-agent-manager-service-account iam.gke.io/gcp-service-account=${GSA_NAME}@{PROJECTID}.iam.gserviceaccount.com
```

For example, the service account for deployment in project _EngineeringDevOps_ is `ds-replication@engineering-devops.iam.gserviceaccount.com`

## Step 3: Deploy DNS load balancers and configure DNS for the clusters
*WARNING*: this will modify the DNS configuration for the entire cluster; if it is shared, it may impact other users.

There is a script provided for this: `etc/multi-region/kubedns/files/multi-region-setup.py`
Run the script with the following arguments:
```
python3 etc/multi-region/kubedns/files/multi-region-setup.py ${NAMESPACE} ${SERVICE_LIST} ${CONTEXT_MAP}
```
where
* `NAMESPACE` is the namespace which is used to deploy the DS instances in all the clusters.
* `SERVICE_LIST` is the list of services deployed in each cluster, separated by a comma. 
   As we are deploying DS CTS and DS IdRepo, this argument should be `ds-cts,ds-idrepo`
* `CONTEXT_MAP` is a map of pairs (region, context), where each element is provided as key:value, 
   and elements are separated by a comma. When deploying to US and Europe, this argument should be 
   `us:gke-us-context,europe:gke-europe-context` where `gke-us-context` is the actual GKE context name of the US cluster 
   and `gke-europe-context` is the actual GKE context name of the Europe cluster.
   The Kustomize files used in deployment in step 4 use the region name (key) provided in the `CONTEXT_MAP` as suffix for _Service name_ and _subdomain_
   (nothing to worry about if you are using the default values provided: _us_ and _europe_).
   Example:
    ```
    europe -> ds-idrepo-europe
    ```

Example:
```
python3 etc/multi-region/kubedns/files/multi-region-setup.py multi-region ds-cts,ds-idrepo us:gke_engineering-devops_us-west2-a_ds-wan-replication-us,europe:gke_engineering-devops_europe-west2-b_ds-wan-replication
```

Once the script is completed, one internal DNS load balancer will be created on each cluster, that will handle the redirection to the other cluster.

## Step 4: Deploy DS using the provided Skaffold profiles
There is script provided to deploy the DS servers in the two clusters: `etc/multi-region/kubedns/files/deploy-ds.sh`

Run the script with the following arguments:
```
etc/multi-region/kubedns/files/deploy-ds.sh ${NAMESPACE} ${US_CONTEXT} ${EUROPE_CONTEXT}
```
where
* `NAMESPACE` is the namespace which is used to deploy the DS instances in all the clusters
* `US_CONTEXT` is the GKE context of the US cluster
* `EUROPE_CONTEXT` is the GKE context of the Europe cluster

Example:
```
etc/multi-region/kubedns/files/deploy-ds.sh multi-region gke_engineering-devops_us-west2-a_ds-wan-replication-us gke_engineering-devops_europe-west2-b_ds-wan-replication
```

## Adapting resources
In case you need to change the default namespace used (_multi-region_), update the following files:
* `kustomize/overlay/multi-region/kubedns-us/kustomization.yaml`
* `kustomize/overlay/multi-region/kubedns-eu/kustomization.yaml`
* `kustomize/overlay/multi-region/multi-region-secrets/kustomization.yaml`

In case you need to change the default region names used (_us_ and _europe_)
Update the following files:
* `kustomize/overlay/multi-region/kubedns-us/kustomization.yaml`
* `kustomize/overlay/multi-region/kubedns-eu/kustomization.yaml`

In these files you need to change the service name for the 2 defined services (_ds-cts_ and _ds-idrepo_):
```
patch: |-
    - op: replace
      path: /metadata/name
      value: >>>>>>ds-idrepo-europe<<<<<<
```
and the subdomain definition for the 2 defined StatefulSets:
```
- |-
    #Patch DS IDREPO
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: ds-idrepo
    spec:
      template:
        spec:
          subdomain: >>>>>>>ds-idrepo-europe<<<<<<<
```
The subdomain must match the service name for each service.
