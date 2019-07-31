#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Script to create a policy to allow access to the specified s3 bucket

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

# Set policy name
IAM_POLICY_NAME="${S3_BUCKET_NAME}-Sync-Policy"

# Create bucket
aws s3 mb s3://${S3_BUCKET_NAME}

# Create bucket policy document
S3_BUCKET_POLICY=$(cat <<-EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": "s3:*",
         "Resource": [
            "arn:aws:s3:::{S3_BUCKET_NAME}",
            "arn:aws:s3:::${S3_BUCKET_NAME}/*"
         ]
      }
   ]
}
EOF
)

# Create policy
POLICY_ARN=$(aws iam create-policy --policy-name ${IAM_POLICY_NAME} --policy-document "${S3_BUCKET_POLICY}" --query Policy.Arn)

echo "IAM policy created with ARN: ${POLICY_ARN}. Please set this ARN value to the S3_POLICY_ARN attribute in your eks-env.cfg file."

# Update bucket permissions to block public access
aws s3api put-public-access-block --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true --bucket ${S3_BUCKET_NAME}
