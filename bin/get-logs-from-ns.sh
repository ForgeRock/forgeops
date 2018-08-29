#!/usr/bin/env bash
#
# Copyright (c) 2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Simple script to get all logs, descriptions, events from selected namespace.
# Useful for faster debugging.
#
: ${NAMESPACE:=smoke}
: ${EXPORT_PATH:=.}

POD_LIST=$(kubectl -n=${NAMESPACE} get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
SERVICE_LIST=$(kubectl -n=${NAMESPACE} get services -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
INGRESS_LIST=$(kubectl -n=${NAMESPACE} get ingress -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
DEPLOYMENT_LIST=$(kubectl -n=${NAMESPACE} get deployment -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')


E_TIME=$(date +%s)
cd ${EXPORT_PATH}
# Make folders for logs
mkdir logs
mkdir logs/pods
mkdir logs/services
mkdir logs/deployments
mkdir logs/ingress


# Get pods/container logs & descriptions
for pod in ${POD_LIST}; do
  echo "Getting POD details from:" ${pod}
  containers=$(kubectl -n=${NAMESPACE} get pod ${pod} -o jsonpath='{.spec.containers[*].name}' | tr " " "\n")
  kubectl -n=${NAMESPACE} describe pod ${pod} > logs/pods/${pod}-description.log
  # Iterate through all containers in pod
  for container in ${containers}; do
    echo "LOG BEGINNING============>" > logs/pods/${pod}-${container}.log
    kubectl -n=${NAMESPACE} logs ${pod} ${container} >> logs/pods/${pod}-${container}.log
    echo "LOG END==================>" >> logs/pods/${pod}-${container}.log
  done
done

# Save service descriptions
for service in ${SERVICE_LIST}; do
  echo "Getting service description from: " ${service}
  echo "LOG BEGINNING============>" > logs/services/${service}.log
  kubectl -n=${NAMESPACE} describe service ${service} >>  logs/services/${service}.log
  echo "LOG END==================>" >>  logs/services/${service}.log
done

for deployment in ${DEPLOYMENT_LIST}; do
  echo "Getting deployment description from: " ${deployment}
  echo "LOG BEGINNING============>" > logs/deployments/${deployment}.log
  kubectl -n=${NAMESPACE} describe deployment ${deployment} >>  logs/deployments/${deployment}.log
  echo "LOG END==================>" >>  logs/deployments/${deployment}.log
done

for ingress in ${INGRESS_LIST}; do
  echo "Getting ingress description from: " ${ingress}
  echo "LOG BEGINNING============>" > logs/ingress/${ingress}.log
  kubectl -n=${NAMESPACE} describe ingress ${ingress} >>  logs/ingress/${ingress}.log
  echo "LOG END==================>" >>  logs/ingress/${ingress}.log
done
