#!/usr/bin/env bash
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to deploy an OpenShift cluster in a new VPC on AWS with cloudformation. 
# This script does not use an IAM role, and assumes the IAM account you are using to launch
# it has admin rights to all services in AWS.

# You must have the AWS CLI installed and configured for the region you are deploying into
# This script has been tested in us-east-1 region


set -o errexit
set -o pipefail
set -o nounset

source ../etc/os-aws-env.cfg

function timer()
{
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local  stime=$1
        etime=$(date '+%s')

        if [[ -z "$stime" ]]; then stime=$etime; fi

        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%d:%02d:%02d' $dh $dm $ds
    fi
}

tmr=$(timer)

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
          --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND

echo "Sleeping 10 seconds to wait for stack status"
sleep 10

while :
do
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name ${OS_AWS_STACK_NAME}|grep StackStatus \
           |sed 's/\"StackStatus\"\: \"//g'|sed 's/\",//g' \
           |sed 's/\"StackStatusReason\"\: \"Stack Create Cancelled//g')

    if [ $STACK_STATUS == "REVIEW_IN_PROGRESS" ]; then
      echo ""
      echo "Current stack status --> REVIEW_IN_PROGRESS"
      echo "Sleeping 1 minute to wait for review to complete"
      sleep 60
    elif [ $STACK_STATUS == "CREATE_IN_PROGRESS" ]; then
      TIME=$(date "+%H:%M:%S")
      echo ""
      echo "Current stack status --> CREATE_IN_PROGRESS"
      echo "Time is now --> ${TIME}"
      printf 'Elapsed time --> %s\n' $(timer $tmr)
      echo "Will check status again in about 10 minutes"
      echo ""
      sleep 600
    elif [ $STACK_STATUS == "CREATE_COMPLETE" ]; then
      echo ""
      echo "Stack deployment completed successfully!"
      printf 'Total elapsed time --> %s\n' $(timer $tmr)
      echo ""
      echo ""
      break
    elif [ $STACK_STATUS == "DELETE_IN_PROGRESS" ] || [ $STACK_STATUS == "CREATE_FAILED" ] \
            || [ $STACK_STATUS == "ROLLBACK_IN_PROGRESS" ]; then
      echo ""
      echo "Stack deployment failed. Exiting the script. Next steps:"
      echo ""
      echo "1) Check cloudformation events for errors and identify / address any issues"
      echo "2) Verify that parameter value settings are correct"
      echo "3) Verify that adequate OpenShift subscription entitlements are available,"
      echo "   and delete any systems that may have registered with subscription manager during"
      echo "   the failed deployment"
      echo "4) Delete the root cloudformation stack (it will delete the nested stacks automatically)"
      echo "5) Retry the stack deployment"
      echo ""
      exit 1
    else
      echo ""
      echo "Unable to determine stack status. Exiting..."
      exit 1
    fi

done

# Display information about OpenShift and establish an SSH session to the ansible-config server
# in the VPC
./os-aws-connect.sh
