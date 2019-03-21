#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Script to create an ec2 key pair

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

aws ec2 create-key-pair --key-name ${EC2_KEYPAIR_NAME}  --query 'KeyMaterial' --output text > ${HOME}/.ssh/${EC2_KEYPAIR_NAME}.pem



