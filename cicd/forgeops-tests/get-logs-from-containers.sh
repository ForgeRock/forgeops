#!/usr/bin/env bash
#
# Simple script to get all logs, descriptions, events from selected namespace.
# Useful for faster debugging.
#

SERVICE="service"
DEPLOYMENT="deployment"
INGRESS="ingress"

: ${NAMESPACE:=smoke}

POD_LIST=$(kubectl -n=${NAMESPACE} get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')

# Go through all pods and get containers for each pod. Get logs from these containers
E_TIME=$(date +%s)
mkdir logs
mkdir logs/${E_TIME}


for pod in ${POD_LIST}; do
  echo "Getting info from:" ${pod}
  containers=$(kubectl -n=${NAMESPACE} get pod ${pod} -o jsonpath='{.spec.containers[*].name}' | tr " " "\n")
  kubectl -n=${NAMESPACE} describe pod ${pod} > logs/${E_TIME}/${pod}-description.log

  for container in ${containers}; do
    echo "LOG BEGINNING============>" > logs/${E_TIME}/${pod}-${container}.log
    kubectl -n=${NAMESPACE} logs ${pod} ${container} >> logs/${E_TIME}/${pod}-${container}.log
    echo "LOG END==================>" >> logs/${E_TIME}/${pod}-${container}.log
  done
done
