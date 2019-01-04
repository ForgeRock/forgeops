#!/bin/bash
#
# Installs and configures required software onto the ansible-config server. 
# Run this script from the ansible-config server after you've cloned the ForgeOps repo.
#


# set -o errexit
set -o pipefail
set -o nounset

source ../etc/os-aws-env.cfg

# Install Docker CE 18.09.0 and dependencies
yum install -y device-mapper-persistent-data \
  lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce-18.09.0
systemctl start docker
systemctl enable docker
docker version

# Informational
echo ""
oc version
echo ""
kubectl version
echo ""

# Create a temporary directory for downloads
mkdir ../tmp
cd ../tmp

# Install Kubectx / Kubens
git clone https://github.com/ahmetb/kubectx
cp ./kubectx/kubectx /usr/bin/kubectx
cp ./kubectx/kubens /usr/bin/kubens


# Install Stern 1.6.0
curl -LO https://github.com/wercker/stern/releases/download/1.6.0/stern_linux_amd64
chmod +x stern_linux_amd64
cp stern_linux_amd64 /usr/bin/stern
stern -v


# Create the Openshift project and namespace
oc new-project ${OS_AWS_CLUSTER_NS}

# Install Helm 2.11.0 into the project
curl -LO https://kubernetes-helm.storage.googleapis.com/helm-v2.11.0-linux-amd64.tar.gz
gunzip helm-v2.11.0-linux-amd64.tar.gz
tar -xvf helm-v2.11.0-linux-amd64.tar
cp ./linux-amd64/helm /usr/bin/helm
export TILLER_NAMESPACE=kube-system
echo "export TILLER_NAMESPACE=kube-system" >> /etc/environment
helm init --client-only
oc process -f ../etc/tiller-template.yaml -p \
   TILLER_NAMESPACE="${TILLER_NAMESPACE}" -p HELM_VERSION=v2.11.0 | oc create -f -

# Need as sometimes tiller is not ready immediately
while :
do
    helm ls >/dev/null 2>&1
    test $? -eq 0 && break
    echo "Waiting on tiller to be ready..."
    sleep 5s
done

# Add forgerock chart repo and display helm version
helm repo add forgerock https://storage.googleapis.com/forgerock-charts
helm version


# Enable helm to deploy a helm chart and pods
oc adm policy add-scc-to-user anyuid -n ${OS_AWS_CLUSTER_NS} -z default
oc policy add-role-to-user admin "system:serviceaccount:${TILLER_NAMESPACE}:tiller"
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:kube-system:tiller

# Clean up temporary directory and files
cd ..
rm -rf tmp
cd bin

# Set the correct region on the AWS CLI
mkdir ~/.aws
echo [default] > ~/.aws/config
echo region = ${OS_AWS_REGION} >> ~/.aws/config

# Prompt user to exit current shell annd create a new one to ensure TILLER_NAMESPACE variable is set
# If it is not set helm commands will fail
echo ""
echo "Prerequisite software installation and configuration completed."
echo ""
echo "Exit the current shell after this script completes and enter \"sudo -s\" before continuing with"
echo "helm chart installations."
echo ""
read -p "Press [Enter] to continue..."




