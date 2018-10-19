#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Script to create a policy to allow access to the specified s3 bucket

BUCKET_ARN="arn:aws:s3:::forgeops"

POLICY_ARN=$(aws iam create-policy --policy-name ForgeOps-S3-Test --policy-document "{    \"Version\": \"2012-10-17\",    \"Statement\": [        {            \"Effect\": \"Allow\",            \"Action\": \"s3:*\",            \"Resource\": [                \"$BUCKET_ARN\",                \"$BUCKET_ARN/*\"            ]        }    ]}" --query Policy.Arn)
echo "ARN for the policy: ${POLICY_ARN}"