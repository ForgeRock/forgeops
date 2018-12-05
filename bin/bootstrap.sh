#!/usr/bin/env bash
# Sample bootstrap script

set -euo pipefail
IFS=$'\n\t'

msg() { echo -e "\\e[32mINFO ---> $1\\e[0m"; }
err() { echo -e "\\e[31mERR ---> $1\\e[0m" ; exit 1; }
check() { command -v "$1" >/dev/null 2>&1 || err "$1 utility is required!"; }

check kubectl
check helm

if ! kubectl cluster-info > /dev/null 2>&1; then
    err "It looks like your cluster is not running or kubectl is not configured"
fi

helmRepoName="forgerock"

helm repo add "$helmRepoName" https://storage.googleapis.com/forgerock-charts > /dev/null

secretName="git-ssh-key"

msg "Checking for the secret ${secretName}"

: "${NAMESPACE:=}"
if [[ -z "$NAMESPACE" ]]; then
    msg "NAMESPACE environment variable is unset, defaulting to default"
    NAMESPACE="default"
fi

if ! kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
    msg "Namespace $NAMESPACE does not exist, creating"
    kubectl create namespace "$NAMESPACE" > /dev/null
fi

if ! kubectl get secret --namespace "$NAMESPACE" "${secretName}" > /dev/null 2>&1; then

    echo
    echo "No ${secretName} secret found for accessing git. A secret will be created for you that allows"
    echo "public read only access to the forgeops-init repo. To create your own secret use "
    echo "the following command to generate a secret:"
    echo
    echo "ssh-keygen -t rsa -C \"forgeopsrobot@forgrock.com\" -f id_rsa -N \"\""
    echo
    echo "The id_rsa.pub file should be uploaded to github and configured as a deployment key for your Git repository"
    echo "Create the Kubernetes secret using the private key:"
    echo
    echo "  kubectl create secret generic \"${secretName}\" --from-file=\"id_rsa\" --namespace \"$NAMESPACE\""
    echo

    ssh-keygen -t rsa -C "forgeopsrobot@forgrock.com" -f id_rsa -N '' > /dev/null

    kubectl create secret generic "${secretName}" --from-file=id_rsa --namespace "$NAMESPACE" > /dev/null
fi

CUSTOM_YAML="config/custom.yaml"

# If there is a config/custom.yaml present, then use it, otherwise create a default one:
if [ ! -r "${CUSTOM_YAML}" ]; then
    msg "I can't find custom.yaml values for the helm chart deployment. I will create a sample for you"

    CUSTOM_YAML="/tmp/custom.yaml"
    DOMAIN=".example.com"
    # TODO: Unused, or meant to be exported?
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

msg "Using values.yaml settings in ${CUSTOM_YAML}"

cat << EOF

You are now ready to install the forgerock helm charts

Example: You can use the following commands to deploy AM

  helm install --namespace "$NAMESPACE" -f ${CUSTOM_YAML} --set instance=configstore $helmRepoName/ds
  helm install --namespace "$NAMESPACE" -f ${CUSTOM_YAML} $helmRepoName/amster
  helm install --namespace "$NAMESPACE" -f ${CUSTOM_YAML} $helmRepoName/openam
EOF