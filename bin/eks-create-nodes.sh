#!/usr/bin/env bash


source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

STACK_NAME=prod-medium-cluster-nodes
CONTROL_PLANE_SG=sg-0a9c85a3ed04xxxxx
EKS_CLUSTER_NAME=prod-medium-cluster
SUBNETS="subnet-0a2d698ebae2xxxxx,subnet-0bb82d200713xxxxx,subnet-09594f97e021xxxxx"
VPC_ID=vpc-0af1b7489239xxxxx
NODE_INS_PROFILE=ami-0440e4f6b971xxxxx
NODE_GROUP_NAME=forgeops-nodegroup
NODE_IMG_ID=ami-0440e4f6b9713faf6
NODE_INS_TYPE="m5.4xlarge"
S3_BUCKET="foregops-bucket"
CLUSTER_ARN="arn:aws:eks:us-east-1:8137593XXXXX:cluster/prod-medium-cluster"

curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-08-30/amazon-eks-nodegroup.yaml

aws cloudformation deploy \
    --stack-name ${STACK_NAME} \
    --template-file amazon-eks-nodegroup.yaml \
    --parameter-overrides NodeInstanceProfile=${INSTANCE_PROFILE_ARN} \
                          NodeInstanceType=${NODE_INS_TYPE} ClusterName=${EKS_CLUSTER_NAME} \
                          NodeGroupName=${NODE_GROUP_NAME} ClusterControlPlaneSecurityGroup=${CONTROL_PLANE_SG} \
                          Subnets=${SUBNETS} VpcId=${VPC_ID} \
    --capabilities CAPABILITY_NAMED_IAM \
    --s3-bucket ${S3_BUCKET} \
    --s3-prefix ${EKS_CLUSTER_NAME} \

#    --no-execute-changeset

# aws cloudformation delete-stack --stack-name ${STACK_NAME}


