#!/usr/bin/env bash
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Updates the IAM profile of the EC2 instances to be able to create and manage EFS resources
# Must be run by a user with administrative rights in IAM.



set -o errexit
set -o pipefail
set -o nounset



# If supplying this script to an AWS admin, uncomment the variable OS_AWS_STACK_NAME and enter
# the same value for used in os-aws-env.cfg. If your AWS IAM account has admin rights
# you can alternatively uncomment the 'source' line so the variable is referenced.


# source "../etc/os-aws-env.cfg"
# OS_AWS_STACK_NAME=""




# Get the name of the IAM role associated with the EC2 instances
OS_AWS_IAM_SETUP_ROLE=$(aws iam list-roles |grep ${OS_AWS_STACK_NAME}-OpenShiftStack|grep SetupRole|grep RoleName|sed 's/\"RoleName\"\: \"//g'|sed 's/\",//g')

# Get the ARN of the EFS full access policy
OS_AWS_IAM_EFS_POLICY=arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess

# Add the policy to the IAM role
aws iam attach-role-policy --role-name ${OS_AWS_IAM_SETUP_ROLE} --policy-arn ${OS_AWS_IAM_EFS_POLICY}
