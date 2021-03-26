#!/usr/bin/env bash

## This script deploys the ForgeRock components to your target Kubernetes cluster. 
set -e 
set -o pipefail

FORGEOPS_REPO="ForgeRock/forgeops"
FORGEOPS_VERSION="latest"
FORGEOPS_NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
FORGEOPS_NAMESPACE="${FORGEOPS_NAMESPACE:-default}"
FORGEOPS_COMPONENT="quickstart"
FORGEOPS_FQDN="default.iam.example.com"
FORGEOPS_URL=""
SECRETAGENT_REPO="ForgeRock/secret-agent"
DSOPERATOR_REPO="ForgeRock/ds-operator"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || (echo "Couldn't determine the root path" ; exit 1) 

usage() {
cat <<EOF
Forgeops Quickstart

A wrapper script that deploys ForgeRock Identity Platform components in your target Kubernetes cluster.

Usage:  quickstart.sh [OPTIONS]

Options:
-n      Target namespace for the deployment. (default: "${FORGEOPS_NAMESPACE}")
-a      FQDN used in the deployment (default: "${FORGEOPS_FQDN}")
-c      Component to install/uninstall. Options: ["base", "ds", "apps", "ui", "am", "idm", "amster", etc] (default: "quickstart")
-f      Forgeops tag/version to install/uninstall (default: "${FORGEOPS_VERSION}")
-u      Uninstalls components
-p      Prints relevant secrets/passwords and relevant urls
-l      Use local (developer) mode. Deploys local manifests. Defaults to nightly docker images.
-h      Prints this message

Examples:
    # deploy using default values
    ${0}
    # deploy to "cdqtest" namespace
    ${0} -n cdqtest
    # uninstall the CDQ from "cdqtest" namespace
    ${0} -n cdqtest -u

EOF
}

## Check and install dependencies
installdependencies () {
    printf "Checking secret-agent operator and related CRDs: "
    if ! $(kubectl get crd secretagentconfigurations.secret-agent.secrets.forgerock.io &> /dev/null); then
        printf "secret-agent CRD not found. Installing secret-agent\n"
        kubectl -n secret-agent-system apply -f "https://github.com/${SECRETAGENT_REPO}/releases/latest/download/secret-agent.yaml"
        echo "Waiting for secret agent operator..."
        sleep 5
        kubectl wait --for=condition=Established crd secretagentconfigurations.secret-agent.secrets.forgerock.io --timeout=30s
        kubectl -n secret-agent-system wait --for=condition=available deployment  --all --timeout=120s 
        kubectl -n secret-agent-system wait --for=condition=ready pod --all --timeout=120s
        echo
    else
        printf "secret-agent CRD found in cluster.\n"
    fi
    printf "Checking ds-operator and related CRDs: "
    if ! $(kubectl get crd directoryservices.directory.forgerock.io &> /dev/null); then
        printf "ds-operator CRD not found. Installing ds-operator\n"
        kubectl -n fr-system apply -f "https://github.com/${DSOPERATOR_REPO}/releases/latest/download/ds-operator.yaml"
        echo "Waiting for ds-operator..."
        sleep 5
        kubectl wait --for=condition=Established crd directoryservices.directory.forgerock.io --timeout=30s
        kubectl -n fr-system wait --for=condition=available deployment  --all --timeout=120s 
        kubectl -n fr-system wait --for=condition=ready pod --all --timeout=120s
        echo
    else
        printf "ds-operator CRD found in cluster.\n"
    fi

}

# Deploy the quickstart
deployquickstart () {
    echo "******Deploying base.yaml. This is a one time activity******"
    deploycomponent "base"
    echo
    echo "******Deploying ds.yaml. This is includes all directory resources******"
    deploycomponent "ds"
    echo 
    echo "******Waiting for git-server and DS pods to come up. This can take several minutes******"
    kubectl -n ${FORGEOPS_NAMESPACE} wait --for=condition=Available deployment -l app.kubernetes.io/name=git-server --timeout=120s
    kubectl -n ${FORGEOPS_NAMESPACE} rollout status --watch statefulset ds-idrepo --timeout=300s
    echo
    echo "******Deploying AM and IDM******"
    deploycomponent "apps"
    echo 
    echo "******Waiting for AM deployment to become available. This can take several minutes******"
    kubectl -n ${FORGEOPS_NAMESPACE} wait --for=condition=Available deployment -l app.kubernetes.io/name=am --timeout=600s
    echo
    echo "******Waiting for amster job to complete. This can take several minutes******"
    kubectl -n ${FORGEOPS_NAMESPACE} wait --for=condition=complete job/amster --timeout=600s
    echo
    echo "Removing \"amster\" deployment."
    uninstallcomponent "amster"
    echo
    echo "******Deploying UI******"
    deploycomponent "ui"
}

# Calculates the targe URL of the desired component
getcomponentURL () {
    if [ "$FORGEOPS_VERSION" == "latest" ]; then
        FORGEOPS_URL="https://github.com/${FORGEOPS_REPO}/releases/latest/download/${1}.yaml"
    else
        FORGEOPS_URL="https://github.com/${FORGEOPS_REPO}/releases/download/${FORGEOPS_VERSION}/${1}.yaml"
    fi
    echo ${FORGEOPS_URL}
}

## Deploy the Component manifest
deploycomponent () {
    if [ ${LOCAL_MODE} = true ]; then
        deploylocalmanifest ${1}
    else
        deployrepomanifest ${1}
    fi
}

## Deploy the Component using released manifest
deployrepomanifest () {

    FORGEOPS_URL=$(getcomponentURL ${1})
    curl -sL ${FORGEOPS_URL} 2>&1 | \
    sed  "s/namespace: default/namespace: ${FORGEOPS_NAMESPACE}/g" | \
    sed  "s/default.iam.example.com/${FORGEOPS_FQDN}/g" | kubectl -n ${FORGEOPS_NAMESPACE} apply -f -
}

## Deploy local component (local mode)
deploylocalmanifest () {
    # Clean out the temp kustomize files
    (cd kustomize/dev/image-defaulter && kustomize edit remove resource ../../../kustomize/*/*/* ../../../kustomize/*/*)
    case "${1}" in
    "base")
        INSTALL_COMPONENTS=("dev/kustomizeConfig" "base/secrets" "base/7.0/ingress" "base/git-server" "dev/scripts")
        ;;
    "ds")
        INSTALL_COMPONENTS=("base/ds-idrepo") #no "ds-cts" in dev-mode
        ;;
    "apps")
        INSTALL_COMPONENTS=("base/amster" "dev/am" "dev/idm" "base/rcs-agent")
        ;;
    "ui")
        INSTALL_COMPONENTS=("base/admin-ui" "base/end-user-ui" "base/login-ui")
        ;;
    "am"|"idm")
        INSTALL_COMPONENTS=("dev/${1}")
        ;;
    *)
        INSTALL_COMPONENTS=("base/${1}")
        ;;
    esac
    # Temporarily add the wanted kustomize files
    for component in "${INSTALL_COMPONENTS[@]}"; do
        (cd kustomize/dev/image-defaulter && kustomize edit add resource ../../../kustomize/${component})
    done
    kustomize build kustomize/dev/image-defaulter 2> /dev/null | \
        sed  "s/namespace: default/namespace: ${FORGEOPS_NAMESPACE}/g" | \
        sed  "s/default.iam.example.com/${FORGEOPS_FQDN}/g" | kubectl -n ${FORGEOPS_NAMESPACE} apply -f -
    # Clean out the temp kustomize files
    (cd kustomize/dev/image-defaulter && kustomize edit remove resource ../../../kustomize/*/*/* ../../../kustomize/*/*)
}

## Uninstall a manifest
uninstallcomponent () {
    FORGEOPS_URL=$(getcomponentURL ${1})
    curl -sL ${FORGEOPS_URL} 2>&1 | \
    sed  "s/namespace: default/namespace: ${FORGEOPS_NAMESPACE}/g" | kubectl -n ${FORGEOPS_NAMESPACE} delete --ignore-not-found=true -f -
    if [[ "$1" == "quickstart" ]]; then
        kubectl -n ${FORGEOPS_NAMESPACE} delete pvc --all --ignore-not-found=true || true
    fi
}

## Wait for secrets to be generated
waitforsecrets () {
    echo ""
    printf "waiting for secret: am-env-secrets ."; until kubectl -n ${FORGEOPS_NAMESPACE} get secret am-env-secrets &> /dev/null ; do sleep 1; printf "."; done ; echo "done"
    printf "waiting for secret: idm-env-secrets ."; until kubectl -n ${FORGEOPS_NAMESPACE} get secret idm-env-secrets &> /dev/null ; do sleep 1; printf "."; done; echo "done"
    printf "waiting for secret: rcs-agent-env-secrets ."; until kubectl -n ${FORGEOPS_NAMESPACE} get secret rcs-agent-env-secrets &> /dev/null ; do sleep 1; printf "."; done; echo "done"
    printf "waiting for secret: ds-passwords ."; until kubectl -n ${FORGEOPS_NAMESPACE} get secret ds-passwords &> /dev/null ; do sleep 1; printf "."; done; echo "done"
    printf "waiting for secret: ds-env-secrets ."; until kubectl -n ${FORGEOPS_NAMESPACE} get secret ds-env-secrets &> /dev/null ; do sleep 1; printf "."; done; echo "done"
}

getsec () {
    kubectl -n ${FORGEOPS_NAMESPACE} get secret $1 -o jsonpath="{.data.$2}" | base64 --decode
}

## Print secrets
printsecrets () {
    echo ""
    echo "Relevant passwords:"
    echo "$(getsec am-env-secrets AM_PASSWORDS_AMADMIN_CLEAR) (amadmin user)"
    echo "$(getsec idm-env-secrets OPENIDM_ADMIN_PASSWORD) (openidm-admin user)"
    echo "$(getsec rcs-agent-env-secrets AGENT_IDM_SECRET) (rcs-agent IDM secret)"
    echo "$(getsec rcs-agent-env-secrets AGENT_RCS_SECRET) (rcs-agent RCS secret)"
    echo "$(getsec ds-passwords dirmanager\\.pw) (uid=admin user)"
    echo "$(getsec ds-env-secrets AM_STORES_APPLICATION_PASSWORD) (App str svc acct (uid=am-config,ou=admins,ou=am-config))"
    echo "$(getsec ds-env-secrets AM_STORES_CTS_PASSWORD) (CTS svc acct (uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens))"
    echo "$(getsec ds-env-secrets AM_STORES_USER_PASSWORD) (ID repo svc acct (uid=am-identity-bind-account,ou=admins,ou=identities))"
}

printurls () {
    echo ""
    echo "Relevant URLs:"
    fqdn=$(kubectl -n ${FORGEOPS_NAMESPACE} get ingress forgerock -o jsonpath="{.spec.rules[0].host}")
    echo "https://${fqdn}/platform"
    echo "https://${fqdn}/admin"
    echo "https://${fqdn}/am"
    echo "https://${fqdn}/enduser"
}

## OSX does not come with `timeout` pre-installed. 
timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }

########################################################################################
################################### MAIN STARTS HERE ###################################
########################################################################################
echo $'\e[5;31m'
echo "**********************************************************************************"
echo "*************THIS SCRIPT IS DEPRECATED. USE /bin/cdk INSTEAD**********************"
echo "**********************************************************************************"
echo $'\e[0m'
UNINSTALL_COMPONENT=false
PRINT_SECRETS=false
LOCAL_MODE=false
# list of arguments expected in the input
optstring=":hupln:f:a:c:"
while getopts ${optstring} arg; do
  case ${arg} in
    h) echo "Usage:"; usage; exit 0;;
    n) FORGEOPS_NAMESPACE=${OPTARG};;
    a) FORGEOPS_FQDN=${OPTARG};;
    c) FORGEOPS_COMPONENT=${OPTARG};;
    f) FORGEOPS_VERSION=${OPTARG};;
    u) UNINSTALL_COMPONENT=true;;
    p) PRINT_SECRETS=true;;
    l) LOCAL_MODE=true;;
    :)
      echo "$0: Must supply an argument to -$OPTARG." >&2
      usage
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      usage
      exit 2
      ;;
  esac
done

# chdir to the forgeops root/..
cd "${SCRIPT_DIR}/.."

if [ ${UNINSTALL_COMPONENT} = true ]; then
    echo
    echo "Using forgeops repo:tag \"${FORGEOPS_REPO}:${FORGEOPS_VERSION}\""
    echo "Targeting namespace: \"${FORGEOPS_NAMESPACE}\""
    echo
    echo "Unistalling component: \"${FORGEOPS_COMPONENT}\""
    uninstallcomponent ${FORGEOPS_COMPONENT}
    exit 0
fi
if [ ${PRINT_SECRETS} = true ]; then
    printsecrets
    printurls
    exit 0
fi
installdependencies
echo
if [ ${LOCAL_MODE} = true ]; then
    echo "Local mode enabled. Using K8s manifests from your local repo"
else
    echo "Using forgeops repo:tag \"${FORGEOPS_REPO}:${FORGEOPS_VERSION}\""
fi
echo "Targeting namespace: \"${FORGEOPS_NAMESPACE}\""
echo
echo "Installing component: \"${FORGEOPS_COMPONENT}\""
if [[ "$FORGEOPS_COMPONENT" == "quickstart" ]]; then
    deployquickstart
else
    deploycomponent ${FORGEOPS_COMPONENT}
fi
# Only print secrets and urls if deploying the quickstart or base
if [[ "$FORGEOPS_COMPONENT" == "quickstart" || "$FORGEOPS_COMPONENT" == "base" ]]; then
    ## Call waitforsecrets with a 2 minute timeout
    timeout 120s cat <( waitforsecrets )
    printsecrets
    printurls
fi

echo ""
echo "Enjoy your \"${FORGEOPS_COMPONENT}\" deployment!"
