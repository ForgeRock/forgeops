#!/usr/bin/env bash
# Example of deploying an nginx ingress controller using Helm.
# On EKS this will configure a Cloud L4 outer load balancer (TCP) and Nginx inside the cluster for L7.
# The loadBalancerIP can be used if you have a static IP to assign to the outer L4 load balancer service.
# If this is not set a dynamic IP will be assigned.
# The publishService.enabled attribute will tell nginx to publish the L4 IP as the ingress IP.

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

# For now we fix the image version at 17.1 as the ingress is not load balancing properly
# See https://github.com/kubernetes/ingress-nginx/issues/3056
helm install --namespace nginx --name nginx \
  --set rbac.create=true \
  --set controller.publishService.enabled=true \
  --set controller.stats.enabled=true \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" \
  stable/nginx-ingress

while :
do
    NLB_STATUS=$(kubectl --namespace nginx get services nginx-nginx-ingress-controller --no-headers -o custom-columns=NAME:.status.loadBalancer.ingress[0].hostname)
    if [ "$NLB_STATUS" == "<none>" ]; then
      echo "Waiting for NLB to initialize DNS"
      sleep 10
    else
      echo "NLB DNS is ready"
      break
    fi

done

echo "=> Creating route53 records for openam and openidm set to point to cluster url"

AM_URL="openam.${EKS_CLUSTER_NS}.${ROUTE53_DOMAIN}"
IDM_URL="openidm.${EKS_CLUSTER_NS}.${ROUTE53_DOMAIN}"

NLB_DNS=$(kubectl --namespace nginx get services nginx-nginx-ingress-controller --no-headers -o custom-columns=NAME:.status.loadBalancer.ingress[0].hostname)

HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name ${ROUTE53_DOMAIN} --query 'HostedZones[0].Id' | sed s/\"//g | sed s/,//g | sed s./hostedzone/..g)
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch '{"Comment":"UPSERT a record ","Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'"${AM_URL}"'","Type":"CNAME","TTL":300,"ResourceRecords":[{"Value":"'"${NLB_DNS}"'"}]}}]}'
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch '{"Comment":"UPSERT a record ","Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'"${IDM_URL}"'","Type":"CNAME","TTL":300,"ResourceRecords":[{"Value":"'"${NLB_DNS}"'"}]}}]}'
