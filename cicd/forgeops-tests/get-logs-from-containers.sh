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
mkdir logs

for pod in ${POD_LIST}; do
  echo "Getting info from:" ${pod}
  containers=$(kubectl -n=${NAMESPACE} get pod ${pod} -o jsonpath='{.spec.containers[*].name}' | tr " " "\n")
  kubectl -n=${NAMESPACE} describe pod ${pod} > logs/${pod}-description.log

  for container in ${containers}; do
    echo "LOG BEGINNING============>" > logs/${pod}-${container}.log
    kubectl -n=${NAMESPACE} logs ${pod} ${container} >> logs/${pod}-${container}.log
    echo "LOG END==================>" >> logs/${pod}-${container}.log
  done
done
