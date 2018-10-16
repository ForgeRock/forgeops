#!/usr/bin/env bash

# This script formats exported Grafana dashboard json files so they are compatible for import into 
# Grafana as part of the Helm release.
#
# PLEASE NOTE!! this script is specific for the currently released ForgeRock dashboards.  
# New dashboards may required some modifications to this script. The Prometheus datasource is often configured as a 
# variable.  Look for this variable in any new dashboards and add an equivalent sed command for to replace it with Prometheus.

DASH_DIR='../helm/forgerock-metrics/dashboards'   # Exported dashboards from Grafana in JSON format.
OVERWRITE=true # Overwrites dashboards of the same name in Grafana.

# Loop through dashboards in dashboards/.  The following alterations are needed to allow the dashboards to be accepted by Grafana:
# 1 - Wrap json content in a dashboard: object
# 2 - Add overwrite option after dashboard content to allow to overwrite current dashboards. Set to true
# 3 - API import doesn't recognise the datasource variables. The values are replaced with Prometheus.
# 4 - Passed into jq command to remove __input section and output in json format.
for dash in $DASH_DIR/*.json; do
    echo `cat $dash` | \
    sed 's/\(.*\)/{"dashboard":\1}/' | \
    sed "s/\(.*\)}/\1,\"overwrite\": ${OVERWRITE}}/" | \
    sed 's/${DS_PROMETHEUS}/prometheus/g' | \
    sed 's/${DS_FORGEROCKDS}/prometheus/g' | \
    sed 's/${DS_FORGEROCKIDM}/prometheus/g' | \
    jq 'del(.dashboard.__inputs)' > ${DASH_DIR}/$(echo ${dash} | cut -d\/ -f 5)
    printf "\nCopied and reformatted $dash \n"
done

# Appended -dashboard to filename as required by Grafana to process it
for f in $DASH_DIR/*.json; do 
    printf '%s\n' "${f%.json}-dashboard.json"; 
    mv $f ${f%.json}-dashboard.json;
done

