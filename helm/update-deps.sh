#!/usr/bin/env bash
# Utility script to update Helm chart dependencies. If you are installing Helm charts from
# the source in this directory, update the dependencies before doing a helm install.

for file in *
do
    # Is it a Helm chart?
    if [ -r $file/Chart.yaml ]; then
        echo "Updating Helm dependencies for $file"
        helm dep up $file
    fi
done