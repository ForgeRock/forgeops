#!/usr/bin/env bash
# Example of deploying an nginx ingress controller using Helm.
# On GKE this will configure a Cloud L4 outer load balancer (TCP) and Nginx inside the cluster for L7.
# The loadBalancerIP can be used if you have a static IP to assign to the outer L4 load balancer service.
# If this is not set a dynamic IP will be assigned.
# The publishService.enabled attribute will tell nginx to publish the L4 IP as the ingress IP.

# Set this IP to your reserved IP. Must be in the same zone as your cluster.

# Handy app for testing your ingress (modify the ingress as needed)
# https://github.com/kubernetes/kubernetes/tree/master/test/e2e/testing-manifests/ingress/http
# commands:
# k apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/test/e2e/testing-manifests/ingress/http/rc.yaml
# k apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/test/e2e/testing-manifests/ingress/http/ing.yaml
# k apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/test/e2e/testing-manifests/ingress/http/svc.yaml


IP=$1

if [ -z $1 ]; then
 IP_OPTS=""
else
 IP_OPTS="--set controller.service.loadBalancerIP=$1"
fi

helm install --namespace nginx --name nginx \
  --set rbac.create=true \
  --set controller.publishService.enabled=true \
  --set controller.stats.enabled=true \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.service.type=LoadBalancer \
  --set controller.image.tag="0.21.0" \
   $IP_OPTS stable/nginx-ingress

#--set controller.image.tag="0.17.1"
#--set enable-dynamic-configuration=false \
