#!/usr/bin/env bash

# This script formats exported Grafana dashboard JSON files so they are compatible for import into 
# Grafana as part of the Helm release.
#
# PLEASE NOTE!! this script is specific for the currently released ForgeRock dashboards.  
# New dashboards may required some modifications to this script. The Prometheus data source is often configured as a 
# variable.  Look for this variable in any new dashboards and add an equivalent sed command to replace it with the string 'Prometheus'.

# A folder containing unprepared exported dashboards from Grafana in JSON format.
# Must be different from PROCESSED_DIR
DASH_DIR='/path/to/dashboards'   

# Folder for processed dashboards.
PROCESSED_DIR='../helm/forgerock-metrics/dashboards' 

# Overwrites dashboards that have the same name in Grafana.
OVERWRITE=true 

# Loop through dashboards in the dashboards directory.  The following changes are needed to allow the dashboards to be accepted by Grafana:
# 1 - Wrap JSON content in a dashboard: object
# 2 - Add overwrite option after dashboard content to allow to overwrite current dashboards. Set to true
# 3 - API import doesn't recognize the data source variables. The values are replaced with `prometheus`.
# 4 - Passed into jq command to remove the __input section and output in JSON format.
for i in $DASH_DIR/*.json; do
    filename=$(basename $i) 
     
    # Carry out steps 1-4 as described above
    echo `cat $i` | \
    sed 's/\(.*\)/{"dashboard":\1}/' | \
    sed "s/\(.*\)}/\1,\"overwrite\": ${OVERWRITE}}/" | \
    sed 's/${DS_PROMETHEUS}/prometheus/g' | \
    sed 's/${DS_FORGEROCKDS}/prometheus/g' | \
    sed 's/${DS_FORGEROCKIDM}/prometheus/g' | \
    jq 'del(.dashboard.__inputs)' > ${PROCESSED_DIR}/$(echo ${filename})
    
    # Append -dashboard to filename
    proc_filename=${PROCESSED_DIR}/$(echo ${filename})
    mv $proc_filename ${proc_filename%.json}-dashboard.json;
    
    printf "\nNew dashboard file: ${proc_filename%.json}-dashboard.json \n"
done

