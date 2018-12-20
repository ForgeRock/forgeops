#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Elastic Kubernetes Service (EKS)
# You must have the aws command installed and access EKS cluster.
# See https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"


# Executing cloudformation script to create worker nodes
aws cloudformation deploy \
          --stack-name $EKS_STACK_NAME \
          --template-file ../etc/amazon-eks-nodegroup.yaml \
          --parameter-overrides KeyName=${EC2_KEYPAIR_NAME} \
                                NodeImageId=${EKS_AMI_ID} \
                                NodeInstanceType=${EKS_WORKER_NODE_INSTANCE_TYPE} \
                                NodeAutoScalingGroupMinSize=${EKS_MIN_NODES} \
                                NodeAutoScalingGroupMaxSize=${EKS_MAX_NODES} \
                                NodeVolumeSize=${EKS_WORKER_NODE_SIZE_IN_GB} \
                                ClusterName=${EKS_CLUSTER_NAME} \
                                NodeGroupName=${EKS_WORKER_NODE_GROUP} \
                                ClusterControlPlaneSecurityGroup=${EC2_SECURITY_GROUP} \
                                VpcId=${EKS_VPC_ID} \
                                Subnets=${EKS_SUBNETS} \
                                S3PolicyArn=${S3_POLICY_ARN} \
                                EFSSecurityGroup=${EFS_SECURITY_GROUP} \
                                --capabilities CAPABILITY_IAM


echo "Worker nodes provisioned. Sleeping for 15 seconds..."

sleep 15

# getting the output of the cloudformation execution. Needed to link the master and worker nodes
NI_ROLE=$(aws cloudformation describe-stacks --stack-name $EKS_STACK_NAME --query 'Stacks[0].Outputs[0].OutputValue' --output text)

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: $NI_ROLE
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF
