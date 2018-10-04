#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

echo "=> Read the following env variables from config file"
echo "Cluster Name = $EKS_CLUSTER_NAME"
echo "Stack Name = $EKS_STACK_NAME"
echo ""

echo "=> Do you want to delete the above cluster?"
read -p "Continue (y/n)?" choice
case "$choice" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit;;
   * ) echo "Invalid input, Bye!"; exit;;
esac

# echo "=> Deleting route53 records for openam and openidm"
AM_URL="openam.${EKS_CLUSTER_NS}.${ROUTE53_DOMAIN}"
IDM_URL="openidm.${EKS_CLUSTER_NS}.${ROUTE53_DOMAIN}"

NLB_DNS=$(kubectl --namespace nginx get services nginx-nginx-ingress-controller --no-headers -o custom-columns=NAME:.status.loadBalancer.ingress[0].hostname)

HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name ${ROUTE53_DOMAIN} --query 'HostedZones[0].Id' | sed s/\"//g | sed s/,//g | sed s./hostedzone/..g)
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch '{"Comment":"DELETE a record ","Changes":[{"Action":"DELETE","ResourceRecordSet":{"Name":"'"${AM_URL}"'","Type":"CNAME","TTL":300,"ResourceRecords":[{"Value":"'"${NLB_DNS}"'"}]}}]}'
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch '{"Comment":"DELETE a record ","Changes":[{"Action":"DELETE","ResourceRecordSet":{"Name":"'"${IDM_URL}"'","Type":"CNAME","TTL":300,"ResourceRecords":[{"Value":"'"${NLB_DNS}"'"}]}}]}'

echo "Removing nginx helm chart..."
helm del --purge nginx || true

echo "Removing ${EKS_MONITORING_NS} namespace..."
kubectl delete namespaces ${EKS_MONITORING_NS} || true
echo "Removing ${EKS_CLUSTER_NS} namespace..."
kubectl delete namespaces ${EKS_CLUSTER_NS} || true

echo "Removing storage classes..."
kubectl delete storageclass fast || true
kubectl delete storageclass standard || true

echo "Deleting the stack: ${EKS_STACK_NAME}"
aws cloudformation delete-stack --stack-name ${EKS_STACK_NAME}

echo "Deleting the cluster: ${EKS_CLUSTER_NAME}"
DELETE_CLUSTER=$(aws eks delete-cluster --name ${EKS_CLUSTER_NAME})