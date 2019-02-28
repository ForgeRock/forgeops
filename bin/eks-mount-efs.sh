#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to mount EFS on EKS cluster worker nodes
# You must have the aws command installed and access EKS cluster.
# See https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

# Get worker node security group id
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=*${EKS_WORKER_NODE_STACK_NAME}-NodeSecurityGroup* --query "SecurityGroups[*].{ID:GroupId}"  | grep ID | awk '{ print $2 }' | cut -d \" -f2)

# Create array of mount target IDs 
MOUNT_TARGETS=$(aws efs describe-mount-targets --file-system-id ${EFS_ID} | grep MountTargetId | awk '{ print $2 }' | cut -d \" -f2)

# Add worker node security group to mount targets
for i in ${MOUNT_TARGETS}
do
    aws efs modify-mount-target-security-groups --mount-target-id $i --security-groups ${SG} ${EFS_SECURITY_GROUP_ID}
    echo "added ${EFS_SECURITY_GROUP_ID} security group to $i mount target"
done

## Add inbound SSH access to worker nodes
aws ec2 authorize-security-group-ingress --group-id $SG  --protocol tcp --port 22 --cidr 0.0.0.0/0 || true

# Get array of worker node external ips
EXTERNAL_IPS=$(kubectl get nodes -o jsonpath={.items[*].status.addresses[?\(@.type==\"ExternalIP\"\)].address})

# Get region name for efs hostname
REGION=$(aws configure get region)

# Loop through each worker node and mount nfs
for ip in ${EXTERNAL_IPS}
do
    ssh -oStrictHostKeyChecking=no -i ~/.ssh/${EC2_KEYPAIR_NAME}.pem ec2-user@${ip} /bin/bash <<EOF
        sudo mount -t nfs ${EFS_ID}.efs.${REGION}.amazonaws.com: /mnt
        if [ ! -d '/mnt/export' ]; then
            sudo mkdir /mnt/export
            sudo mkdir /mnt/export/bak
        fi
        echo -e "Worker node ${ip} mounted to EFS \n"
EOF
done
