#!/usr/bin/env bash
# Creates the firewall rule to allow mesh clusters to talk to each other.

NETWORK=forgeops


CONTROL_POD_CIDR=$(gcloud container clusters describe eng-shared --zone us-east1-c --format=json | jq -r '.clusterIpv4Cidr')
REMOTE_POD_CIDR=$(gcloud container clusters describe ds-wan-replication --zone europe-west2-b --format=json | jq -r '.clusterIpv4Cidr')
CONTROL_PRIMARY_CIDR=$(gcloud compute networks subnets describe $NETWORK --region=us-east1 --format=json | jq -r '.ipCidrRange')
REMOTE_PRIMARY_CIDR=$(gcloud compute networks subnets describe $NETWORK --region=europe-west2 --format=json | jq -r '.ipCidrRange')

ALL_CLUSTER_CIDRS=$CONTROL_POD_CIDR,$REMOTE_POD_CIDR,$CONTROL_PRIMARY_CIDR,$REMOTE_PRIMARY_CIDR

ALL_CLUSTER_NETTAGS=$(gcloud compute instances list --format=json | jq -r '.[].tags.items[0]' | uniq | awk -vORS=, '{ print $1 }' | sed 's/,$/\n/')

gcloud compute firewall-rules delete istio-multicluster-rule

gcloud compute firewall-rules create istio-multicluster-rule \
    --network $NETWORK \
    --allow=tcp,udp,icmp,esp,ah,sctp \
    --direction=INGRESS \
    --priority=900 \
    --source-ranges="${ALL_CLUSTER_CIDRS}" \
    --target-tags="${ALL_CLUSTER_NETTAGS}"
