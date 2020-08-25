#!/usr/bin/env bash
# Provision EKS cluster using eksctl
# ./e

set -o errexit
set -o pipefail
set -o nounset

usage() {
    printf "\nUsage: $0 <config file>\n\n"
    exit 1
}

if [[ "$#" != 1 ]]; then
    usage
else
 # Check if yaml file exists
    if test -f "$1"; then
        file=$1
    else
        printf "\nProvided config file name doesn't exist\n\n"
        exit 1
    fi

    # Get values from yaml file
    cluster_name=$(grep -A1 '^metadata:$' $file | tail -n1 | awk '{ print $2 }')
fi

echo "Deleting cluster ${cluster_name}..."
eksctl delete cluster --name $cluster_name --wait