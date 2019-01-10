#!/usr/bin/env bash
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# This script displays information about the OpenShift ELB that is used for container access, as
# well as the URL to access the OpenShift web interface. In addition, it will establish an interactive SSH
# session to the ansible-config host using the private key information you specified in the os-aws-env.cfg file. 
# Runs as part of the installation but can be used as needed.


set -o errexit
set -o pipefail
set -o nounset

source "../etc/os-aws-env.cfg"


# Informational
aws cloudformation describe-stacks --stack-name $OS_AWS_STACK_NAME --output table --query 'Stacks[0].Outputs'
export OS_AWS_ANSIBLE_HOST=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=ansible-configserver' --query 'Reservations[0].Instances[0].PublicDnsName'|sed s/\"//g)
echo ""
echo ""
echo "Your ansible host public DNS registration is ---> ${OS_AWS_ANSIBLE_HOST}"
echo ""

# Establish an interactive SSH session to the ansible jumpbox in the VPC
echo "Adding the private key to the local ssh agent"
echo ""
ssh-add ${OS_AWS_PRIVATE_KEY_PATH}
echo ""
echo ""
echo "Attempting to establish an interactive SSH session to the ansible jumbox in the VPC."
echo "Once connected, enter \"sudo -s\" and you will now have access to the OpenShift \"oc\" commands"
echo "and can view the ansible configuration in \"/etc/ansible/hosts\". Respond \"yes\" if prompted"
echo "to confirm you want to connect. If the connection fails, check the os-aws-env.cfg file and" 
echo "verify your private key settings and that you are connecting from the IP network you specified."
echo ""
ssh -A ec2-user@${OS_AWS_ANSIBLE_HOST}


