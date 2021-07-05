#!/usr/bin/env bash

set -o errexit

# Specify your cluster names
CLUSTER1="clouddns-eu"
CLUSTER2="clouddns-us"

#### Don't edit below here ####

create_firewall_rule() {
    cluster_location=$(gcloud container clusters list |grep $2 | awk '{print $2}')
    local source_range=$(gcloud container clusters describe $2 --zone $cluster_location --format="value(clusterIpv4Cidr)")

    # Check firewall rules doesn't already exist
    exists=$(gcloud -q compute firewall-rules list | grep "$1 ") && true

    [ -n "$exists" ] && echo "** Firewall $1 already exists, please delete **" && exit 1

    gcloud compute firewall-rules create $1 \
        --allow tcp:8989 \
        --source-ranges $source_range \
        --target-tags $3 \
        --direction ingress
}

# Get compute instance name
instance1=$(gcloud compute instances list |grep $CLUSTER1 | awk 'NR==1{print $1}')
[ -z $instance1 ] && echo "** No compute instances found for $CLUSTER1 **" && exit 1

instance2=$(gcloud compute instances list |grep $CLUSTER2 | awk 'NR==1{print $1}')
[ -z $instance2 ] && echo "** No compute instances found for $CLUSTER2 **"  && exit 1

# Get instance zone
zone1=$(gcloud compute instances list |grep $instance1 | awk 'NR==1{print $2}')
zone2=$(gcloud compute instances list |grep $instance2 | awk 'NR==1{print $2}')

# Get network tag of compute instance
tag1=$(gcloud compute instances describe $instance1 --zone=$zone1 --format="value(tags.items[0])")
tag2=$(gcloud compute instances describe $instance2 --zone=$zone2 --format="value(tags.items[0])")

# Create firewall rules
echo "Creating firewall rules..."
create_firewall_rule $CLUSTER1 $CLUSTER2 $tag1 $zone2
create_firewall_rule $CLUSTER2 $CLUSTER1 $tag2 $zone1




