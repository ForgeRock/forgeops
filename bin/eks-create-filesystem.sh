#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Elastic Kubernetes Service (EKS)
# You must have the aws command installed and access EKS cluster.
# See https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html

# Creating a security group for the NFS

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

EFS_GROUP_ID=$(aws ec2 create-security-group --description "Security group used for NFS mount" --group-name ${EFS_SECURITY_GROUP_NAME} --vpc-id ${EKS_VPC_ID} --query 'GroupId' --output text)

echo "EFS Security Group created with ID: ${EFS_GROUP_ID}. Please set this value to the EFS_SECURITY_GROUP_ID attribute in your eks-env.cfg file."

EFS_ID=$(aws efs create-file-system --performance-mode maxIO --creation-token EKSNFSMount --query 'FileSystemId' --output text)

while :
do
    EFS_STATUS=$(aws efs describe-file-systems \
                      --file-system-id ${EFS_ID} --query 'FileSystems[0].LifeCycleState' --output text)

    if [ $EFS_STATUS == "available" ]; then
      echo "File system created with ID: ${EFS_ID}. Please add this ID to the EFS_ID value in the template. This id will also be used to configure backup and restore."
      break
    else
      sleep 10
      echo "Waiting for EFS volume..."
    fi

done

for subnet in $(echo $EKS_SUBNETS | tr "," "\n")
do
  aws efs create-mount-target --file-system-id ${EFS_ID} --subnet-id ${subnet}
done

# Allow worker nodes access to EFS
aws ec2 authorize-security-group-ingress --group-id ${EFS_GROUP_ID} \
    --protocol tcp \
    --port 2049 \
    --source-group ${EKS_CONTROL_PLANE_SECURITY_GROUP}
