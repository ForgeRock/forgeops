#!/bin/bash
# Called by os-aws-required-software.sh
# Sets RBAC permissions for helm. The oc adm commands need to run directly on the first master.
# OS_AWS_FIRST_MASTER_HOSTNAME and OS_AWS_CLUSTER_NS will be replaced by the calling script.

# Enable helm to deploy a helm chart and pods

ssh OS_AWS_FIRST_MASTER_HOSTNAME "oc adm policy add-scc-to-user anyuid -n OS_AWS_CLUSTER_NS -z default"
ssh OS_AWS_FIRST_MASTER_HOSTNAME 'oc policy add-role-to-user admin "system:serviceaccount:kube-system:tiller"'
ssh OS_AWS_FIRST_MASTER_HOSTNAME "oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:kube-system:tiller"