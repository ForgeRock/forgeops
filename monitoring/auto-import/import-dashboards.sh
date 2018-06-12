#!/usr/bin/env bash

DASH_DIR="dashboards"
PROCESSED_DIR="processed-dashboards"
KEY="YWRtaW46YWRtaW4="
#HOST="http://localhost:3000"  # for testing locally
HOST="monitoring-kube-prometheus-grafana:80"
OVERWRITE=true

# Check Grafana endpoint returns 200
while true; do
    HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" ${HOST})
    HTTP_STATUS=$(echo $HTTP_RESPONSE  | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    if [ $HTTP_STATUS -eq 200  ]; then
        break
    fi
    printf "Grafana endpoint not ready..."
    sleep 5
done

# Loop through dashboards in dashboards/.  The following alerations are needed to allow uploading via Grafana API:
# 1 - Wrap json content in a dashboard: object
# 2 - Add overwrite option after dashboard content to allow to overwrite current dashboards. Set to true
# 3 - API import doesn't recognise the datasource variables. The values are replaced with Prometheus.
# 4 - Passed into jq command to output in json format and redirect file into processed-dashboards/.
# 5 - Posted dashboards to Grafana API.
for dash in $DASH_DIR/*.json; do
    echo `cat $dash` | \
    #sed 's/"id": [0-9],/"id":null,/' | \
    sed 's/\(.*\)/{"dashboard":\1}/' | \
    sed "s/\(.*\)}/\1,\"overwrite\": ${OVERWRITE}}/" | \
    sed 's/${DS_PROMETHEUS}/prometheus/g' | \
    sed 's/${DS_FORGEROCKDS}/prometheus/g' | \
    sed 's/${DS_FORGEROCKIDM}/prometheus/g' | \
    jq 'del(.dashboard.__inputs)' > ${PROCESSED_DIR}/$(echo ${dash} | cut -d\/ -f 2)
    printf "\nCopied and reformatted $dash \n"
    curl -f -k -XPOST -H "Authorization: Basic ${KEY}"  -H "Content-Type: application/json" -H "Accept: application/json" ${HOST}/api/dashboards/db -d @${PROCESSED_DIR}/$(echo ${dash} | cut -d\/ -f 2)
done
