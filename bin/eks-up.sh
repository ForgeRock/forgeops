#!/usr/bin/env bash
# Sample wrapper script to initialize AWS. This creates the cluster and configures Helm, the nginx ingress,
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

if ! [ -x "$(command -v aws-iam-authenticator)" ]; then
  echo "ERROR: aws-iam-authenticator is not found in your PATH." >&2
  exit 1
fi 

echo -e "WARNING: The following components must be initialized before deployment:\n\t-IAM Service Role\n\t-VPC/Subnets\n\t-Control Plane Security Group\n These pre-requisites are outlined in the DevOps Documentation. Please ensure you have completed all before proceeding."

echo ""
echo "=> Have you copied the template file etc/eks-env.template to etc/eks-env.cfg and edited to cater to your enviroment?"
ask

EKS_AUTH=$(aws sts get-caller-identity --output text --query 'Arn')
echo ""
echo "You are authenticated and logged into AWS as \"${EKS_AUTH}\". If this is not correct then exit this script and run \"aws configure\" to login into the correct account first."
ask

#source "$(dirname $0)/../etc/eks-env.cfg"
source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

# Now create the cluster
./eks-create-cluster.sh

if [ $? -ne 0 ]; then
    exit 1
fi

# Create worker nodes
./eks-create-worker-nodes.sh

# Create monitoring namespace
kubectl create namespace ${EKS_MONITORING_NS}

# Create the namespace parsed from cfg file and set the context
kubectl create namespace ${EKS_CLUSTER_NS}
kubectl config set-context $(kubectl config current-context) --namespace=${EKS_CLUSTER_NS}

# Create helm rbac
./helm-rbac-init.sh

# Need as sometimes tiller is not ready immediately
while :
do
    helm ls >/dev/null 2>&1
    test $? -eq 0 && break
    echo "Waiting on tiller to be ready..."
    sleep 5s
done

# Create Ingress controller
./eks-create-ingress-cntlr.sh

# Create storage class
./eks-create-sc.sh

# Deploy cert-manager. Disabled for now. -- use ./generate-tls.sh
#./deploy-cert-manager.sh

# Add Prometheus
./deploy-prometheus.sh

echo "Please add 'export KUBECONFIG=$KUBECONFIG:~/.kube/config-eks' to your bash_profile"
