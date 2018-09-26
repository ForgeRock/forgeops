#!/usr/bin/env bash

###################################################################################
# Deployment script that can be used for CI automation, etc.
# This script assumes that kubectl and helm are available, and have been configured
# with the correct context for the cluster.
# Warning: This script will purge any existig deployments in the target namespace!
#
# This script will also do the following:
#   - Deploy AM along with DS (configstore, userstore and CTS)
#   - Ensure configs are in place
#   - Restart AM to take all configuration online
####################################################################################

set -o errexit
set -o pipefail
set -o nounset

usage()
{
    echo "Usage: $0 [-f config.yaml] [-e env.sh] [-n namespace] [-R] [-d] config_directory"
    echo "-f extra config yaml that will be passed to helm. May be repeated."
    echo "-e extra env.sh that will be sourced to set environment variables."
    echo "-n set the namespace. Override values in env.sh."
    echo "-R Remove all.  Purge any existing deployment (Warning - destructive)."
    echo "-d dryrun. Show the helm commands that would be executed but do not deploy any charts."
    exit 1
}


parse_args()
{
    while getopts "df:e:n:R" opt; do
        case ${opt} in
            f ) YAML="$YAML -f ${OPTARG} " ;;
            e ) ENV_SH="${OPTARG}" ;;
            R ) RMALL=true ;;
            d ) DRYRUN="echo " ;;
            n ) OPT_NAMESPACE="${OPTARG}" ;;
            \? ) usage ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -ne 1 ]; then
         echo "Error: Missing deployment config directory"
         usage
    fi

    CFGDIR="$1"

}

chk_config()
{
    CONTEXT=$(kubectl config current-context)
    if [ $? != 0 ]; then
        echo "ERROR: Your k8s Context is not set.  Please set it before running this script. Exiting!"
        exit 1
    fi
    echo "=> k8s Context is: \"${CONTEXT}\""

    #if [ "${CONTEXT}" = "minikube" ]; then
    #    echo "=> Minikube deployment detected.  Installing tiller..."
    #    helm init --service-account default --upgrade
    #    echo "=> Giving tiller few seconds to get ready..."
    #    sleep 30s
    #fi

    if [ -z "${CFGDIR}" ] || [ ! -d "${CFGDIR}" ]; then
        echo "ERROR: Configuration directory path not given or inaccessable.  Exiting!"
        exit 1
    else
        echo "=> Using \"${CFGDIR}\" as the root of your configuration"
        echo "=> Reading env.sh"
        if [ -r  ${CFGDIR}/env.sh ]; then
            echo "=> Reading ${CFGDIR}/env.sh"
            source ${CFGDIR}/env.sh
        fi
        # We want env.sh provided on the command line to take precedence.
         if [ ! -z "${ENV_SH}" ]; then
            echo "=> Reading ${ENV_SH}"
            source "${ENV_SH}"
        fi
    fi

    # Allow overriding namespace
    if [ ! -z "$OPT_NAMESPACE" ]; then
        NAMESPACE="$OPT_NAMESPACE"
    fi

    if [ -z "${NAMESPACE}" ]; then
        echo "ERROR: Your Namespace is not set for the deployment. Exiting!"
        exit 1
    fi
    echo -e "=>\tNamespace: \"${NAMESPACE}\""

    if [ -z "${DOMAIN}" ]; then
        echo "ERROR: Your Domain is not set for the deployment. Exiting!"
        exit 1
    fi
    echo -e "=>\tDomain: \"${DOMAIN}\""

    if [ -z "${COMPONENTS}" ]; then
        COMPONENTS=(frconfig configstore userstore ctsstore openam amster)
    fi
    echo -e "=>\tComponents: \"${COMPONENTS[*]}\""

    AM_URL="${URL_PREFIX:-openam}.${NAMESPACE}.${DOMAIN}"
}


create_namespace()
{
    if [ "${RMALL}" = true ]; then
        echo "=> Removing all components of the deployment from ${NAMESPACE}"
        ${DIR}/bin/remove-all.sh -N ${NAMESPACE}
    fi

    if $(kubectl get namespace ${NAMESPACE} > /dev/null 2>&1); then
        echo "=> Namespace ${NAMESPACE} already exists.  Skipping creation..."
    else
        echo "=> Creating namespace \"${NAMESPACE}\""
        kubectl create namespace ${NAMESPACE}
        if [ $? -ne 0 ]; then
            echo "Non-zero return by kubectl.  Is your context correct? Exiting!"
            exit 1
        fi
    fi
}

# todo: this should decode and install any secrets we need. The git-ssh-key, for example
create_secrets()
{
    echo "to do"
}

#### Deploy methods
deploy_charts()
{
    echo "=> Deploying charts into namespace \"${NAMESPACE}\" with URL \"${AM_URL}\""

    # If the deploy directory contains a common.yaml, prepend it to the helm arguments.
    if [ -r "${CFGDIR}"/common.yaml ]; then
        YAML="-f ${CFGDIR}/common.yaml $YAML"
    fi

    # These are the charts (components) that will be deployed via helm
    for comp in ${COMPONENTS[@]}; do
        chart="${comp}"
        case "${comp}" in
          *store)
            chart="ds"
            ;;
        esac

        CHART_YAML=""
        if [ -r  "${CFGDIR}/${comp}.yaml" ]; then
           CHART_YAML="-f ${CFGDIR}/${comp}.yaml"
        fi

        ${DRYRUN} helm install --name ${comp}-${NAMESPACE} \
            ${YAML} ${CHART_YAML} \
            --namespace=${NAMESPACE} ${DIR}/helm/${chart}
    done
}

isalive_check()
{
    PROTO="https"
    if [[ -f ${CFGDIR}/openam.yaml || -f ${CFGDIR}/common.yaml ]]; then
        if $(grep -sq -e '^tlsStrategy:\s*\bhttp\b' ${CFGDIR}/common.yaml ${CFGDIR}/openam.yaml); then
            PROTO="http"
        fi
    fi
    ALIVE_JSP="${PROTO}://${AM_URL}/openam/isAlive.jsp"
    echo "=> Testing ${ALIVE_JSP}"
    STATUS_CODE="503"
    until [ "${STATUS_CODE}" = "200" ]; do
        echo "   ${ALIVE_JSP} is not alive, waiting 10 seconds before retry..."
        sleep 10
        STATUS_CODE=$(curl -k -LI  ${ALIVE_JSP} -o /dev/null -w '%{http_code}\n' -s)
    done
    echo "=> AM is alive"
}

import_check()
{
    # This live check waits for AM config to be imported.
    # We are looking at amster pod logs periodically.
    echo "=> Live check - waiting for config to be imported to AM";
    sleep 10
    FINISHED_STRING="Configuration script finished"

    AMSTER_POD_NAME=$(kubectl -n=${NAMESPACE} get pods --selector=component=amster \
        -o jsonpath='{.items[*].metadata.name}')

    while true; do
        echo "Inspecting amster pod: ${AMSTER_POD_NAME}"
        OUTPUT=$(kubectl -n=${NAMESPACE} logs ${AMSTER_POD_NAME} amster || true)
        if [[ "$OUTPUT" = *$FINISHED_STRING* ]]; then
            echo "=> AM configuration import is finished"
            break
        fi
        echo "=> Configuration not finished yet. Waiting for 10 seconds...."
        sleep 10
    done
}

restart_am()
{  
    OPENAM_POD_NAME=$(kubectl -n=${NAMESPACE} get pods --selector=app=openam \
        -o jsonpath='{.items[*].metadata.name}')
    echo "=> Deleting \"${OPENAM_POD_NAME}\" to restart and read newly imported configuration"
    kubectl delete pod $OPENAM_POD_NAME --namespace=${NAMESPACE}
    if [ $? -ne 0 ]; then
        echo "Could not delete AM pod.  Please check error and fix."
    fi
    sleep 10
    isalive_check
}

scale_am()
{
    echo "=> Scaling AM deployment..."
    DEPNAME=$(kubectl get deployment -l app=openam -o name)
    kubectl scale --replicas=2 ${DEPNAME} || true
    if [ $? -ne 0 ]; then
        echo "Could not scale AM deployment.  Please check error and fix."
    fi
}

scale_idm()
{
    echo "=> Scaling IDM deployment..."
    DEPNAME=$(kubectl get deployment -l app=openidm -o name)
    kubectl scale --replicas=2 ${DEPNAME} || true
    if [ $? -ne 0 ]; then
        echo "Could not scale IDM deployment.  Please check error and fix."
    fi
}

deploy_hpa()
{
    echo "=> Deploying Horizontal Autoscale Chart..."
    kubectl apply -f ${CFGDIR}/hpa.yaml || true
    if [ $? -ne 0 ]; then
        echo "Could not deploy HPA.  Please check error and fix."
    fi
}


###############################################################################
# main
###############################################################################

YAML="" # Additional YAML options for helm
ENV_SH="" 
OPT_NAMESPACE=""
RMALL=false
DRYRUN=""
CONTEXT=""

# All helm chart paths are relative to this directory.
DIR=`echo $(dirname "$0")/..`

parse_args "$@"
chk_config

# Dryrun? Just show what helm commands would be executed.
if [ ! -z "$DRYRUN" ]; then
    deploy_charts
    exit 0
fi

create_namespace
deploy_charts

if [[ " ${COMPONENTS[@]} " =~ " openam " ]]; then
    echo "AM is present in deployment, running AM live checks"
    import_check
    restart_am
fi

# Do not scale or deploy hpa on minikube
if [ "${CONTEXT}" != "minikube" ]; then
    if [[ " ${COMPONENTS[@]} " =~ " openam " ]]; then
      scale_am
    fi
    
    if [[ " ${COMPONENTS[@]} " =~ " openidm " ]]; then
      scale_idm
    fi
    #deploy_hpa # TODO
fi

# Schedule directory backup
echo ""
echo "=> For each directory pod you want to backup execute the following command"
echo "   $ kubectl exec -it <podname> scripts/schedule-backup.sh"

printf "\e[38;5;40m=======> Deployment is ready <========\n"



