#!/usr/bin/env bash
# Example of deploying an nginx ingress controller using Helm.
# On GKE this will configure a Cloud L4 outer load balancer (TCP) and Nginx inside the cluster for L7.
# The loadBalancerIP can be used if you have a static IP to assign to the outer L4 load balancer service.
# If this is not set a dynamic IP will be assigned.
# The publishService.enabled attribute will tell nginx to publish the L4 IP as the ingress IP.

# Set this IP to your reserved IP. Must be in the same zone as your cluster.

IP=$1

if [ -z $IP ]; then
  echo "Creating Ingress Controller without IP"
  helm install --namespace nginx --name nginx  \
    --set rbac.create=true \
    --set controller.publishService.enabled=true \
    --set controller.stats.enabled=true \
    stable/nginx-ingress
else
  echo "Creating Ingress Controller with IP=$IP"
  helm install --namespace nginx --name nginx  \
    --set rbac.create=true \
    --set controller.service.loadBalancerIP=$IP \
    --set controller.publishService.enabled=true \
    --set controller.stats.enabled=true \
    stable/nginx-ingress
fi

