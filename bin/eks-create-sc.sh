#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Elastic Kubernetes Service (EKS)
# You must have the aws command installed and access EKS cluster.
# See https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html



# Creates storage classes for fas and standard volumes.
# Fast volumes are only supports for AWS instance types C5, C5d, i3.metal, M5,
# M5d, R5, R5d, T3, u-6tb1.metal, u-9tb1.metal, u-12tb1.metal, and z1d.
# For io1 the maximum ratio of provisioned IOPS to requested volume size (in GiB) is 50:1.
# For example, a 100 GiB volume can be provisioned with up to 5,000 IOPS.
# Check this page out for more details https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumeTypes.html


kubectl create -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: fast
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: fast10
provisioner: kubernetes.io/aws-ebs
parameters:
  type: io1
  fstype: ext4
  iopsPerGB: "10"
EOF


kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

kubectl delete storageclass gp2


