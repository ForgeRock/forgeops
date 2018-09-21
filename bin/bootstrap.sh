#!/usr/bin/env bash
# Sample bootstrap script
#set -x

msg() { echo -e "\e[32mINFO ---> $1\e[0m"; }
err() { echo -e "\e[31mERR ---> $1\e[0m" ; exit 1; }
check() { command -v "$1" >/dev/null 2>&1 || err "$1 utility is required!"; }

check kubectl
check helm

if ! kubectl cluster-info; then
    echo "It looks like your cluster is not running or kubectl is not configured"
    exit 1
fi


helm repo add forgerock https://storage.googleapis.com/forgerock-charts


secretName="git-ssh-key"

echo "Checking for the secret ${secretName}"

if ! kubectl get secret --namespace "${NAMESPACE}" "${secretName}"; then
    echo "No ${secretName} secret found for accessing git. A secret will be created for you that allows"
    echo "public read only access to the forgeops-init repo. To create your own secret use "
    echo "the following command to generate a secret:"
    echo "ssh-keygen -t rsa -C \"forgeopsrobot@forgrock.com\" -f id_rsa -N ''"
    echo "The id_rsa.pub file should be uploaded to github and configured as a deployment key for your Git repository"
    echo "Create the Kubernetes secret using the private key:"
    echo "kubectl create secret generic "${secretName}" --from-file=id_rsa"

    ssh-keygen -t rsa -C "forgeopsrobot@forgrock.com" -f id_rsa -N ''

    kubectl create secret generic "${secretName}" --from-file=id_rsa

fi


CUSTOM_YAML=config/custom.yaml

# If there is a conf/custom.yaml present, then use it, otherwise create a default one:
if [ ! -r "${CUSTOM_YAML}" ]; then
    echo "I can't find custom.yaml values for the helm chart deployment. I will create a sample for you"

    CUSTOM_YAML=/tmp/custom.yaml
    DOMAIN=.example.com
    REPO="forgerock-docker-public.bintray.io/forgerock/forgerock"

    cat > ${CUSTOM_YAML} <<EOF
global:
  domain: ${DOMAIN}
  git:
    repo: "https://github.com/ForgeRock/forgeops-init.git"
    branch: master
  configPath:
    idm:  default/idm/sync-with-ldap-bidirectional
    am:   default/am/empty-import
    ig:   default/ig/basic-sample
  exportPath:
    am: default/am/dev
EOF

fi

echo "Using values.yaml settings in ${CUSTOM_YAML}"

echo "You are now ready to install the forgerock helm charts"

echo "Example: You can use the following commands to deploy AM"

echo "helm install -f ${CUSTOM_YAML} --set instance=configstore ds"
echo "helm install -f ${CUSTOM_YAML} amster"
echo "helm install -f ${CUSTOM_YAML} openam"
