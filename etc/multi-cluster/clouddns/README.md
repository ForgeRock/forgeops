# Multi-cluster deployment for DS on GKE using CloudDNS for GKE

>`CloudDNS for GKE is currently in Preview.`

Doc: https://cloud.google.com/kubernetes-engine/docs/how-to/cloud-dns#enabling_scope_dns_in_a_new_cluster  

## Overview
This guide explains how to deploy DS in 2 different regions on GKE, using one cluster in the US and one cluster in Europe.
For different cluster names, just replace *eu* and *us* in the various files mentioned in the setup steps below .

There are 4 major steps to the deployment:
* Prepare 2 clusters configured for CloudDNS, one in the US and one in Europe.
* Enable the use of shared secrets across the clusters.
* Create firewall rules to allow replication traffic between clusters.
* Prepare kustomize configuration to ensure unique server IDs and configure bootstrap servers.
* Deploy DS using the provided Skaffold profiles.

## Step 1: Prepare clusters
#
Provision 2 clusters with following requirements:
  * Same VPC
  * In different regions if multi-region(below example is configured in eu and us)
  * Create same namespace in each cluster for DS (default: prod).
  * Workload Identity enabled(for Secret Agent).
  * Configure CloudDNS domain name(see below) 

Create your cluster as described in the forgeops docs but also include the following arguments where cluster domain will be the domain configured for that cluster e.g. the following will replace pod domain `.cluster.local` with `.us` for the us cluster:
```bash
  --cluster-dns clouddns \
  --cluster-dns-scope vpc \
  --cluster-dns-domain us
```

There is a helpful script to create your cluster [cluster-up.sh](https://github.com/ForgeRock/forgeops/blob/master/cluster/gke/cluster-up.sh)

Just edit the [multi-cluster.sh](https://github.com/ForgeRock/forgeops/blob/master/cluster/gke/multi-cluster.sh) file with your cluster spec and CLOUD_DNS_DOMAIN then run the following commands:  
```bash
source cluster/gke/multi-cluster.sh
cluster/gke/cluster-up.sh
```

## Step 2: Configure firewall rules
#
Firewall rules need to be created to allow replication traffic between clusters.
Either manually create firewall rules or there is a sample bash script that will create these for you.  
```bash
/etc/multi-cluster/clouddns/create-firewall-rules.sh
```

Just edit the cluster names at the top of the script.
```yaml
# Specify your cluster names
CLUSTER1="clouddns-eu"
CLUSTER2="clouddns-us"
```

Firewall rules will be generated with these cluster names.


## Step 3: Enable the use of shared secrets across the clusters
# 
Deploy secret-agent in each cluster:
```bash
bin/secret-agent.sh
```
Follow instructions to configure secret-agent to work with Workload Identity: [Instructions](https://github.com/ForgeRock/secret-agent#set-up-cloud-backup-with-gcp-secret-manager)  
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

**2. Configure clusters**  

>`NOTE:` Currently these files are configured based on eu and us regions. These values must match the value provided for `--cluster-dns-domain`  names registered in step 1.

Change the DS_CLUSTER_TOPOLOGY env var for a different list of regional identifiers.

See `kustomize/overlay/multi-cluster/clouddns/<region>/kustomization.yaml`  

```yaml
              env: 
              - name: DS_CLUSTER_TOPOLOGY
                value: "eu,us"
```

Bootstrap servers are also explicitly configured in the kustomization.yaml.  Bootstrap servers need to be configured for both idrepo and cts.  Switch the eu or us with your own domain name.  

```yaml
              - name: DS_BOOTSTRAP_REPLICATION_SERVERS
                value: "ds-cts-0.ds-cts-us.prod.svc.us:8989,ds-cts-0.ds-cts-eu.prod.svc.eu:8989"
````

The above change needs to be applied to the idrepo and cts patch in both regional kustomization.yaml files.  
<br />

**3. Add Skaffold profiles**  
>`NOTE:` Required step 

Add the following profiles to Skaffold.yaml:  
```yaml
- name: clouddns-us
  build:
    artifacts:
    - *DS-CTS
    - *DS-IDREPO
    tagPolicy:
      sha256: { }
  deploy:
    kustomize:
      path: ./kustomize/overlay/multi-cluster/clouddns/us
  
- name: clouddns-eu
  build:
    artifacts:
    - *DS-CTS
    - *DS-IDREPO
    tagPolicy:
      sha256: { }
  deploy:
    kustomize:
      path: ./kustomize/overlay/multi-cluster/clouddns/eu
```  
<br />  

## Step 4: Deploy
#  

Deploy to US:
```bash
skaffold run --profile clouddns-us
```

Deploy to EU:
```bash
skaffold run --profile clouddns-eu
```

