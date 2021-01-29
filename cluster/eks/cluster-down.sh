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

echo "The \"${cluster_name}\" cluster will be deleted. This action cannot be undone."
echo "Press any key to continue, or CTRL+C to quit"
read;

read -r -p "Do you want to delete all PVCs allocated by this cluster (recommended for dev clusters)? [Y/N] " response
case "$response" in
    [nN][oO]|[nN]) 
        echo
        echo "***The following PVCs will not be removed. You're responsible to remove them later***"
        kubectl get pvc --all-namespaces --no-headers
        ;;
    [yY][eE][sS]|[yY]) 
        echo
        echo "***Draining all nodes***"
        kubectl cordon -l forgerock.io/cluster
        kubectl delete pod --all-namespaces --all --grace-period=0
        echo
        echo "***Deleting all PVCs***"
        kubectl delete pvc --all-namespaces --all
        ;;
    *)
        echo "Invalid option. Please try again."
        exit 1
        ;;
esac

# Attempt to release any L4 service load balancers
echo 
echo "***Cleaning all services and load balancers if any***"
kubectl delete svc --all --all-namespaces

echo
echo "***Deleting cluster \"${cluster_name}\" in 5 seconds. CTRL+C now to stop***"
sleep 5
eksctl delete cluster --config-file $file --wait