#!/usr/bin/env bash
# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Azure Kubernetes Service (AKS)
# You must have the az command installed and access AKS cluster.

# See https://docs.microsoft.com/en-us/azure/aks/azure-disks-dynamic-pv#built-in-storage-classes
#     https://docs.microsoft.com/en-us/azure/virtual-machines/windows/premium-storage
#     https://kubernetes.io/docs/concepts/storage/storage-classes/#azure-disk

# This standard sc is the same as "default" and the fast is same as "managed-premium"
kubectl create -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: standard
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Standard_LRS
  kind: managed
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: fast
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
EOF

#kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

