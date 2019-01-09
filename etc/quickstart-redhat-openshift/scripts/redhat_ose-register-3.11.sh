#!/bin/bash -e

source ${P}

#Attach to Subscription pool

yum clean all
rm -rf /var/cache/yum

CREDS=$(aws secretsmanager get-secret-value --secret-id ${1} --region ${AWS_REGION} --query SecretString --output text)
REDHAT_USERNAME=$(echo ${CREDS} | jq -r .user)
REDHAT_PASSWORD=$(echo ${CREDS} | jq -r .password)
REDHAT_POOLID=$(echo ${CREDS} | jq -r .poolid)

qs_retry_command 20 subscription-manager register --username=${REDHAT_USERNAME} --password=${REDHAT_PASSWORD} --force
qs_retry_command 20 subscription-manager attach --pool=${REDHAT_POOLID}
qs_retry_command 20 subscription-manager status
qs_retry_command 20 subscription-manager repos --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.11-rpms" \
    --enable="rhel-7-fast-datapath-rpms" \
    --enable="rhel-7-server-ansible-2.6-rpms" \
    --enable="rh-gluster-3-client-for-rhel-7-server-rpms"

var=($(subscription-manager identity))
UUID="${var[2]}"
aws ec2 create-tags --resources ${INSTANCE_ID} --tags Key=UUID,Value=$UUID --region ${AWS_REGION}
