#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Script to create a policy to allow access to the specified s3 bucket

BUCKET_NAME="fops1"
IAM_POLICY_NAME="ForgeOps-Sync-Policy"

S3_BUCKET=$(aws s3api create-bucket --bucket ${BUCKET_NAME})

BUCKET_ARN="arn:aws:s3:::${BUCKET_NAME}"

POLICY_ARN=$(aws iam create-policy --policy-name ${IAM_POLICY_NAME} --policy-document "{    \"Version\": \"2012-10-17\",    \"Statement\": [        {            \"Effect\": \"Allow\",            \"Action\": \"s3:*\",            \"Resource\": [                \"$BUCKET_ARN\",                \"$BUCKET_ARN/*\"            ]        }    ]}" --query Policy.Arn)

echo "IAM policy created with ARN: ${POLICY_ARN}. Please set this ARN value to the S3_POLICY_ARN attribute in your eks-env.cfg file."
