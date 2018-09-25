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

echo -e "WARNING: This script requires a properly provisioned AWS Services with appropriate\n\t accounts, roles, privileges, keyrings, keys etc. These pre-requisites are\n\t outlined in the DevOps Documentation. Please ensure you have completed all\n\t before proceeding."


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

# Create worker nodes
./eks-create-worker-nodes.sh

if [ $? -ne 0 ]; then
    exit 1
fi
