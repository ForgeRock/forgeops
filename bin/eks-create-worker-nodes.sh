#!/usr/bin/env bash

# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create the worker nodes for a previously created EKS cluster using cloudformation


set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

aws cloudformation deploy \
          --stack-name $EKS_STACK_NAME \
          --template-file ../etc/amazon-eks-nodegroup.yaml \
          --parameter-overrides KeyName=${EKS_SSH_KEYPAIR_NAME} \
                                NodeImageId=${EKS_AMI_ID} \
                                NodeInstanceType=${EKS_WORKER_NODE_INSTANCE_TYPE} \
                                NodeAutoScalingGroupMinSize=${EKS_MIN_NODES} \
                                NodeAutoScalingGroupMaxSize=${EKS_MAX_NODES} \
                                NodeVolumeSize=${EKS_WORKER_NODE_SIZE_IN_GB} \
                                ClusterName=${EKS_CLUSTER_NAME} \
                                NodeGroupName=${EKS_WORKER_NODES_GROUP} \
                                ClusterControlPlaneSecurityGroup=${EKS_SECURITY_GROUPS} \
                                VpcId=${EKS_VPC_ID} \
                                Subnets=${EKS_SUBNETS} \
                                --capabilities CAPABILITY_IAM

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


#TARGET_ARN=`aws elbv2 create-target-group --name $EKS_CLUSTER_NAME-tg --protocol http --port 80 --vpc-id $EKS_VPC_ID --query 'TargetGroups[0].TargetGroupArn'`
