#!/usr/bin/env bash
#
# Copyright (c) 2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Simple script to get all logs, descriptions, events from selected namespace.
# Useful for faster debugging.
#
# Set NAMESPACE & EXPORT_PATH env vars to match your needs
#

: ${NAMESPACE:=smoke}
: ${EXPORT_PATH:=.}

# TODO - Add line limitation

# Get all running pods, services, deployments and ingresses in namespace
POD_LIST=$(kubectl -n=${NAMESPACE} get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
SERVICE_LIST=$(kubectl -n=${NAMESPACE} get services -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
INGRESS_LIST=$(kubectl -n=${NAMESPACE} get ingress -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
DEPLOYMENT_LIST=$(kubectl -n=${NAMESPACE} get deployment -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')

cd ${EXPORT_PATH}

# Make folders for logs
E_TIME=$(date +%s)
if [ ! -d "logs" ]; then
  mkdir logs
fi

mkdir logs/${E_TIME}
cd logs/${E_TIME}

mkdir pods
mkdir services
mkdir deployments
mkdir ingress


# Get pods/container logs & descriptions
for pod in ${POD_LIST}; do
  echo "Getting POD details from:" ${pod}
  init_containers=$(kubectl -n=${NAMESPACE} get pod ${pod} -o jsonpath='{.spec.initContainers[*].name}' | tr " " "\n")
  containers=$(kubectl -n=${NAMESPACE} get pod ${pod} -o jsonpath='{.spec.containers[*].name}' | tr " " "\n")
  kubectl -n=${NAMESPACE} describe pod ${pod} > pods/${pod}-description.log
  # Iterate through all containers in pod
  for container in ${init_containers}; do
        kubectl -n=${NAMESPACE} logs ${pod} ${container} > pods/${pod}-init-${container}.log
  done
  for container in ${containers}; do
    kubectl -n=${NAMESPACE} logs ${pod} ${container} > pods/${pod}-${container}.log
  done
done

# Save service descriptions
for service in ${SERVICE_LIST}; do
  echo "Getting service description from: " ${service}
  kubectl -n=${NAMESPACE} describe service ${service} >  services/${service}.log
done

for deployment in ${DEPLOYMENT_LIST}; do
  echo "Getting deployment description from: " ${deployment}
  kubectl -n=${NAMESPACE} describe deployment ${deployment} > deployments/${deployment}.log
done

for ingress in ${INGRESS_LIST}; do
  echo "Getting ingress description from: " ${ingress}
  kubectl -n=${NAMESPACE} describe ingress ${ingress} > ingress/${ingress}.log
done
