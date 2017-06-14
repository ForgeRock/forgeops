#!/usr/bin/env bash
# Example of deploying an nginx ingress controller using Helm.
# On GKE this will configure a Cloud L4 outer load balancer (TCP) and Nginx inside the cluster for L7.
# The loadBalancerIP can be used if you have a static IP to assign to the outer L4 load balancer service.
# If this is not set a dynamic IP will be assigned.
helm install --namespace nginx  --set "controller.service.loadBalancerIP=35.184.100.105" stable/nginx-ingress




