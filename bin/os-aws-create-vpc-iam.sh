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

aws cloudformation deploy \
          --stack-name $OS_AWS_STACK_NAME \
          --template-file ../etc/openshift-master.template \
          --parameter-overrides AvailabilityZones=${OS_AWS_AVAILABILITY_ZONES} \
                                VPCCIDR=${OS_AWS_VPC_CIDR} \
                                PrivateSubnet1CIDR=${OS_AWS_PRIVATE_SUBNET_1_CIDR} \
                                PrivateSubnet2CIDR=${OS_AWS_PRIVATE_SUBNET_2_CIDR} \
                                PrivateSubnet3CIDR=${OS_AWS_PRIVATE_SUBNET_3_CIDR} \
                                PublicSubnet1CIDR=${OS_AWS_PUBLIC_SUBNET_1_CIDR} \
                                PublicSubnet2CIDR=${OS_AWS_PUBLIC_SUBNET_2_CIDR} \
                                PublicSubnet3CIDR=${OS_AWS_PUBLIC_SUBNET_3_CIDR} \
                                RemoteAccessCIDR=${OS_AWS_REMOTE_ACCESS_CIDR} \
                                ContainerAccessCIDR=${OS_AWS_CONTAINER_ACCESS_CIDR} \
                                DomainName=${OS_AWS_DOMAIN_NAME} \
                                HostedZoneID=${OS_AWS_HOSTED_ZONE_ID} \
                                SubDomainPrefix=${OS_AWS_SUB_DOMAIN_PREFIX} \
                                KeyPairName=${OS_AWS_KEY_PAIR_NAME} \
                                NumberOfMaster=${OS_AWS_NUMBER_OF_MASTER} \
                                NumberOfEtcd=${OS_AWS_NUMBER_OF_ETCD} \
                                NumberOfNodes=${OS_AWS_NUMBER_OF_NODES} \
                                MasterInstanceType=${OS_AWS_MASTER_INSTANCE_TYPE} \
                                EtcdInstanceType=${OS_AWS_ETCD_INSTANCE_TYPE} \
                                NodesInstanceType=${OS_AWS_NODES_INSTANCE_TYPE} \
                                OpenShiftAdminPassword=${OS_AWS_OPENSHIFT_ADMIN_PASSWORD} \
                                OpenshiftContainerPlatformVersion=${OS_AWS_OPENSHIFT_CONTAINER_PLATFORM_VERSION} \
                                AWSServiceBroker=${OS_AWS_SERVICE_BROKER} \
                                HawkularMetrics=${OS_AWS_HAWKULAR_METRICS} \
                                AnsibleFromGit=${OS_AWS_ANSIBLE_FROM_GIT} \
                                ClusterName=${OS_AWS_CLUSTER_NAME} \
                                ClusterConsole=${OS_AWS_CLUSTER_CONSOLE} \
                                GlusterFS=${OS_AWS_GLUSTER_FS} \
                                GlusterStorageSize=${OS_AWS_GLUSTER_STORAGE_SIZE} \
                                GlusterStorageType=${OS_AWS_STORAGE_TYPE} \
                                GlusterStorageIops=${OS_AWS_GLUSTER_STORAGE_IOPS} \
                                GlusterStorageEncrypted=${OS_AWS_GLUSTER_STORAGE_ENCRYPTED} \
                                GlusterInstanceType=${OS_AWS_GLUSTER_INSTANCE_TYPE} \
                                NumberOfGluster=${OS_AWS_NUMBER_OF_GLUSTER} \
                                AutomationBroker=${OS_AWS_AUTOMATION_BROKER} \
                                RedhatSubscriptionUserName=${OS_AWS_REDHAT_SUBSCRIPTION_USER_NAME} \
                                RedhatSubscriptionPassword=${OS_AWS_REDHAT_SUBSCRIPTION_PASSWORD} \
                                RedhatSubscriptionPoolID=${OS_AWS_REDHAT_SUBSCRIPTION_POOL_ID} \
                                QSS3BucketName=${OS_AWS_QS_S3_BUCKET_NAME} \
                                QSS3KeyPrefix=${OS_AWS_QS_S3_KEY_PREFIX} \
                                OutputBucketName=${OS_AWS_OUTPUT_BUCKET_NAME} \
          --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
          --role-arn ${OS_AWS_IAM_Role}

