#!/bin/bash
#
# Installs and configures required software onto the ansible-config server. 
# Run this script from the ansible-config server after you've cloned the ForgeOps repo.
#


set -o errexit
set -o pipefail
set -o nounset

# Install Docker CE 18.09.0
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


# Install Helm 2.11.0 into it's own OpenShift project and add ForgeRock charts
oc new-project tiller
curl -LO https://kubernetes-helm.storage.googleapis.com/helm-v2.11.0-linux-amd64.tar.gz
gunzip helm-v2.11.0-linux-amd64.tar.gz
tar -xvf helm-v2.11.0-linux-amd64.tar
cp ./linux-amd64/helm /usr/bin/helm
export TILLER_NAMESPACE=tiller
echo "export TILLER_NAMESPACE=tiller" >> /etc/environment
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
helm repo add forgerock https://storage.googleapis.com/forgerock-charts
helm version

# Create the prod Openshift project and namespace
oc new-project prod

# Enable helm to deploy a helm chart and pods in the prod project
oc adm policy add-scc-to-user anyuid -n prod -z default
oc policy add-role-to-user admin "system:serviceaccount:${TILLER_NAMESPACE}:tiller"

# Clean up temporary directory and files
cd ..
rm -rf tmp
cd bin



