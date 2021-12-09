# Multi-cluster deployment for DS on GKE using Cloud DNS for GKE

>`Cloud DNS for GKE is currently in Preview.`

Doc: https://cloud.google.com/kubernetes-engine/docs/how-to/cloud-dns#enabling_scope_dns_in_a_new_cluster  

## Overview
This guide explains how to deploy DS across 2 different GKE clusters, using one cluster in the US and one cluster in Europe.
For different cluster names, just replace *eu* and *us* in the various files mentioned in the setup steps below .

There are 5 major steps to the deployment:
* Prepare 2 clusters configured to use Cloud DNS with one in the US and one in Europe.
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
  * Configure your Cloud DNS domain name(see below) 

Create your cluster as described in the forgeops docs but also include the following arguments where cluster domain will be the domain configured for that cluster e.g. the following will replace pod domain `.cluster.local` with `.us` for the us cluster:
```bash
  --cluster-dns clouddns \
  --cluster-dns-scope vpc \
  --cluster-dns-domain us
```

There is a helpful script to create your cluster [cluster-up.sh](https://github.com/ForgeRock/forgeops/blob/master/cluster/gke/cluster-up.sh)

Edit the [multi-cluster.sh](https://github.com/ForgeRock/forgeops/blob/master/cluster/gke/multi-cluster.sh) file with your cluster spec including required values for:
* CLOUD_DNS_DOMAIN
* REGION

Then run the following commands:  
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

See `ds-idrepo.yaml` and `ds-cts.yaml` in kustomize/overlay/multi-cluster/clouddns.  

```yaml
              env: 
              - name: DS_CLUSTER_TOPOLOGY
                value: "eu,us"
```

The above change needs to be applied to the idrepo and cts patch in the ds-cts.yaml and ds-idrepo.yaml files.  
<br />

## Step 4: Deploy
#  

Deploy following profile to both clusters:
```bash
skaffold run --profile clouddns
```

## Step 5: Verify replication
#  

The best way to check replication is using Grafana.  This can be deployed as part of the Prometheus Operator Helm chart package using our sample script:

```bash
bin/prometheus-deploy.sh
```

Connect to Grafana:

```bash
kubectl port-forward $(kubectl get  pods --selector="app.kubernetes.io/name=grafana" --field-selector status.phase=Running --output=jsonpath="{.items..metadata.name}" --namespace=$NAMESPACE) $PORT:3000 --namespace=$NAMESPACE
```

Then type `localhost:3000` in your browser to view Grafana.

Go to the ForgeRock Directory Services dashboard and look at the receive delay graph to confirm that ds pods in each cluster are receiving traffic from each other.

![receive-delay-graph](receive-delay.png)

If traffic isn't replicating between clusters, then revisit the steps in this readme and check the Google Cloud documentation described [here](https://cloud.google.com/kubernetes-engine/docs/how-to/cloud-dns)

## Step 6: Delete
#  

In each cluster run:
```bash
skaffold delete --profile clouddns
# Only run the following command if you want to delete all data
kubectl delete pvc --all
# To retain the idrepo pvcs if you want to hold on to the users
kubectl delete pvc data-ds-cts-0 data-ds-cts-1 data-ds-cts-2
```

Cleanup:
* delete clusters
* delete firewall rules(look for Ingress firewall rules with the same name as your cluster) (https://console.cloud.google.com/networking/firewalls/list?project=<projectID>)