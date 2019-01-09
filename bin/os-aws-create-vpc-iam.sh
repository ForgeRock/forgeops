#!/usr/bin/env bash
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to deploy an OpenShift cluster in a new VPC on AWS with cloudformation 
# using a pre-existing IAM role

# You must have the AWS CLI installed and configured for the region you are deploying into
# This script has been tested in us-east-1 region




set -o pipefail
set -o nounset

source ../etc/os-aws-env.cfg

aws cloudformation create-stack \
          --stack-name $OS_AWS_STACK_NAME \
          --template-url https://s3.amazonaws.com/${OS_AWS_QS_S3_BUCKET_NAME}/${OS_AWS_QS_S3_KEY_PREFIX}templates/openshift-master.template \
          --parameters  ParameterKey=AvailabilityZones,ParameterValue=${OS_AWS_AVAILABILITY_ZONE_1}\\,${OS_AWS_AVAILABILITY_ZONE_2}\\,${OS_AWS_AVAILABILITY_ZONE_3} \
                        ParameterKey=VPCCIDR,ParameterValue=${OS_AWS_VPC_CIDR} \
                        ParameterKey=PrivateSubnet1CIDR,ParameterValue=${OS_AWS_PRIVATE_SUBNET_1_CIDR} \
                        ParameterKey=PrivateSubnet2CIDR,ParameterValue=${OS_AWS_PRIVATE_SUBNET_2_CIDR} \
                        ParameterKey=PrivateSubnet3CIDR,ParameterValue=${OS_AWS_PRIVATE_SUBNET_3_CIDR} \
                        ParameterKey=PublicSubnet1CIDR,ParameterValue=${OS_AWS_PUBLIC_SUBNET_1_CIDR} \
                        ParameterKey=PublicSubnet2CIDR,ParameterValue=${OS_AWS_PUBLIC_SUBNET_2_CIDR} \
                        ParameterKey=PublicSubnet3CIDR,ParameterValue=${OS_AWS_PUBLIC_SUBNET_3_CIDR} \
                        ParameterKey=RemoteAccessCIDR,ParameterValue=${OS_AWS_REMOTE_ACCESS_CIDR} \
                        ParameterKey=ContainerAccessCIDR,ParameterValue=${OS_AWS_CONTAINER_ACCESS_CIDR} \
                        ParameterKey=DomainName,ParameterValue=${OS_AWS_DOMAIN_NAME} \
                        ParameterKey=HostedZoneID,ParameterValue=${OS_AWS_HOSTED_ZONE_ID} \
                        ParameterKey=SubDomainPrefix,ParameterValue=${OS_AWS_SUB_DOMAIN_PREFIX} \
                        ParameterKey=KeyPairName,ParameterValue=${OS_AWS_KEY_PAIR_NAME} \
                        ParameterKey=NumberOfMaster,ParameterValue=${OS_AWS_NUMBER_OF_MASTER} \
                        ParameterKey=NumberOfEtcd,ParameterValue=${OS_AWS_NUMBER_OF_ETCD} \
                        ParameterKey=NumberOfNodes,ParameterValue=${OS_AWS_NUMBER_OF_NODES} \
                        ParameterKey=MasterInstanceType,ParameterValue=${OS_AWS_MASTER_INSTANCE_TYPE} \
                        ParameterKey=EtcdInstanceType,ParameterValue=${OS_AWS_ETCD_INSTANCE_TYPE} \
                        ParameterKey=NodesInstanceType,ParameterValue=${OS_AWS_NODES_INSTANCE_TYPE} \
                        ParameterKey=OpenShiftAdminPassword,ParameterValue=${OS_AWS_OPENSHIFT_ADMIN_PASSWORD} \
                        ParameterKey=OpenshiftContainerPlatformVersion,ParameterValue=${OS_AWS_OPENSHIFT_CONTAINER_PLATFORM_VERSION} \
                        ParameterKey=AWSServiceBroker,ParameterValue=${OS_AWS_SERVICE_BROKER} \
                        ParameterKey=HawkularMetrics,ParameterValue=${OS_AWS_HAWKULAR_METRICS} \
                        ParameterKey=AnsibleFromGit,ParameterValue=${OS_AWS_ANSIBLE_FROM_GIT} \
                        ParameterKey=ClusterName,ParameterValue=${OS_AWS_CLUSTER_NAME} \
                        ParameterKey=ClusterConsole,ParameterValue=${OS_AWS_CLUSTER_CONSOLE} \
                        ParameterKey=GlusterFS,ParameterValue=${OS_AWS_GLUSTER_FS} \
                        ParameterKey=GlusterStorageSize,ParameterValue=${OS_AWS_GLUSTER_STORAGE_SIZE} \
                        ParameterKey=GlusterStorageType,ParameterValue=${OS_AWS_STORAGE_TYPE} \
                        ParameterKey=GlusterStorageIops,ParameterValue=${OS_AWS_GLUSTER_STORAGE_IOPS} \
                        ParameterKey=GlusterStorageEncrypted,ParameterValue=${OS_AWS_GLUSTER_STORAGE_ENCRYPTED} \
                        ParameterKey=GlusterInstanceType,ParameterValue=${OS_AWS_GLUSTER_INSTANCE_TYPE} \
                        ParameterKey=NumberOfGluster,ParameterValue=${OS_AWS_NUMBER_OF_GLUSTER} \
                        ParameterKey=AutomationBroker,ParameterValue=${OS_AWS_AUTOMATION_BROKER} \
                        ParameterKey=RedhatSubscriptionUserName,ParameterValue=${OS_AWS_REDHAT_SUBSCRIPTION_USER_NAME} \
                        ParameterKey=RedhatSubscriptionPassword,ParameterValue=${OS_AWS_REDHAT_SUBSCRIPTION_PASSWORD} \
                        ParameterKey=RedhatSubscriptionPoolID,ParameterValue=${OS_AWS_REDHAT_SUBSCRIPTION_POOL_ID} \
                        ParameterKey=QSS3BucketName,ParameterValue=${OS_AWS_QS_S3_BUCKET_NAME} \
                        ParameterKey=QSS3KeyPrefix,ParameterValue=${OS_AWS_QS_S3_KEY_PREFIX} \
                        ParameterKey=OutputBucketName,ParameterValue=${OS_AWS_OUTPUT_BUCKET_NAME} \
          --role-arn ${OS_AWS_IAM_Role}

