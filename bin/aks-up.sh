#!/usr/bin/env bash
# Sample wrapper script to initialize AKS. This creates the cluster and configures Helm, the nginx ingress,
# and creates git credential secrets. Edit this for your requirements.

set -o errexit
set -o pipefail
set -o nounset

ask() {

        read -p "Should i continue (y/n)?" choice
        case "$choice" in
                y|Y|yes|YES ) echo "yes";;
                n|N|no|NO ) echo "no"; exit 1;;
                * ) echo "Invalid input, Bye!"; exit 1;;
        esac
}

echo -e "WARNING: This script requires an existing Service Principal. Other\n\t pre-requisites are outlined in the DevOps Documentation.\n\t Please ensure you have completed all before proceeding."


echo ""
echo "=> Have you copied the template file etc/aks-env.template to etc/aks-env.cfg and edited to cater to your enviroment?"
ask

authn=$(az ad signed-in-user show | grep userPrincipalName | awk -F: '{print $2}' | sed 's/,//g')
echo ""
echo -e "=> You are authenticated and logged into Azure as ${authn}. \n   If this is not correct then exit this script and run \"az login\" to login with the correct user.\n   NOTE: The Service Principal for creating the Kubernetes Cluster can be different and should\n   already exist in the aks-env.cfg file."
ask

source "${BASH_SOURCE%/*}/../etc/aks-env.cfg"

# Now create the cluster
./aks-create-cluster.sh

if [ $? -ne 0 ]; then
    exit 1
fi

# Create monitoring namespace
kubectl create namespace ${AKS_MONITORING_NS}

# Create the namespace parsed from cfg file and set the context
kubectl create namespace ${AKS_CLUSTER_NS}
kubectl config set-context $(kubectl config current-context) --namespace=${AKS_CLUSTER_NS}

# Create storage class
./aks-create-sc.sh

# Inatilize helm by creating a rbac role first
./helm-rbac-init.sh

# Need as sometimes tiller is not ready immediately
while :
do
    helm ls >/dev/null 2>&1
    test $? -eq 0 && break
    echo "Waiting on tiller to be ready..."
    sleep 5s
done


# Create the ingress controller
./gke-create-ingress-cntlr.sh 

# Deploy cert-manager
./deploy-cert-manager.sh

# Add Prometheus
./deploy-prometheus.sh

# Filestore is needed if you enable backups.  Uncomment the next line to create one.
# ./aks-create-filestore.sh
