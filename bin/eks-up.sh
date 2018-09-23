#!/usr/bin/env bash
# Sample wrapper script to initialize EKS. This creates the cluster and configures Helm, the nginx ingress,
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

#echo -e "WARNING: This script requires a properly provisioned GCP Project with appropriate\n\t accounts, roles, privileges, keyrings, keys etc. These pre-requisites are\n\t outlined in the DevOps Documentation. Please ensure you have completed all\n\t before proceeding."


#echo ""
#echo "=> Have you copied the template file etc/eks-env.template to etc/eks-env.cfg and edited to cater to your enviroment?"
#ask

#authn=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
#echo ""
#echo "You are authenticated and logged into GCP as \"${authn}\". If this is not correct then exit this script and run \"gcloud auth login\" to login into the correct account first."
#ask

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

# Set the EKS Project Name to the one parsed from the cfg file
#gcloud config set project ${EKS_PROJECT_NAME} 

# Now create the cluster
#./eks-create-cluster.sh

#if [ $? -ne 0 ]; then
#    exit 1 
#fi

# Add a nodepool for nfs server
./eks-create-nodes.sh 

# Create monitoring namespace
kubectl create namespace ${EKS_MONITORING_NS}

# Create the namespace parsed from cfg file and set the context
kubectl create namespace ${EKS_CLUSTER_NS}
kubectl config set-context $(kubectl config current-context) --namespace=${EKS_CLUSTER_NS}

# Create storage class
./eks-create-sc.sh

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
./create-ingress-cntlr.sh ${EKS_INGRESS_IP}

# Deploy cert-manager
./deploy-cert-manager.sh

# Add Prometheus
./deploy-prometheus.sh
