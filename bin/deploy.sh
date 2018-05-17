#!/bin/bash

###################################################################################
# Deployment script that can be used for CI automation, etc.
# This script assumes that kubectl and helm are available, and have been configured
# with the correct context for the cluster.
# Warning: This script will purge any existig deployments in the target namespace!
#
# This script will also do the following:
#   - Deploy OpenAM along with DS (configstore, userstore and CTS)
#   - Ensure configs are in place
#   - Restart OpenAM to take all configuration online
####################################################################################

usage() 
{
    echo "Usage: $0 [-f config.yaml] [-e env.sh] [-R] [-d] config_directory"
    echo "-f extra config yaml that will be passed to helm. May be repeated"
    echo "-e extra env.sh that will be sourced to set environment variables. May be repeated"
    echo "-R Remove all.  Purge any existing deployment (Warning - destructive)"
    echo "-d dryrun. Show the helm commands that would be executed but do not deploy any charts"
    exit 1
}
# Additional YAML options for helm
YAML=""

parse()
{
    while getopts "df:e:R" opt; do
        case ${opt} in
            f ) YAML="$YAML -f ${OPTARG} " ;;
            e ) ENV_SH="${OPTARG}" ;;
            R ) RMALL=true ;;
            d ) DRYRUN="echo " ;;
            \? ) usage ;;
        esac
    done
    shift $((OPTIND -1))
 
    if [ "$#" -ne 1 ]; then
         echo "Error: Missing deployment directory"
         usage
    fi

    CFGDIR="$1"
}

chk_config()
{
    context=$(kubectl config current-context)
    if [ $? != 0 ]; then
        echo "ERROR: Your k8s Context is not set.  Please set it before running this script. Exiting!"
        exit 1
    fi
    echo "=> k8s Context is: \"${context}\""

    if [ -z "${CFGDIR}" ] || [ ! -d "${CFGDIR}" ]; then 
        echo "ERROR: Configuration directory path not given or inaccessable.  Exiting!"
        exit 1
    else
        echo "=> Using \"${CFGDIR}\" as the root of your configuration"
        echo "=> Reading env.sh"
        if [ ! -z "${ENV_SH}" ]; then
            echo "=> Reading ${ENV_SH}"
            source "${ENV_SH}"
        fi
        if [ -r  ${CFGDIR}/env.sh ]; then 
            echo "=> Reading ${CFGDIR}/env.sh"
            source ${CFGDIR}/env.sh
        fi
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
        bin/remove-all.sh ${NAMESPACE}
    fi

    echo "=> Creating namespace \"${NAMESPACE}\". Ignore errors below if already exists"
    kubectl create namespace ${NAMESPACE}
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

    # If the deploy directory contains a common.yaml, append it to the helm arguments.
    if [ -r "${CFGDIR}"/common.yaml ]; then
        YAML="$YAML -f ${CFGDIR}/common.yaml"
    fi

    # These are the charts (components) that will be deployed via helm 
    for comp in ${COMPONENTS[@]}; do
        chart="${comp}"
        case "${comp}" in
          *store)
            chart="opendj"
            ;;
        esac

        ${DRYRUN} helm install --name ${comp}-${NAMESPACE} ${YAML} \
            -f ${CFGDIR}/${comp}.yaml \
            --namespace=${NAMESPACE} ${DIR}/helm/${chart}
    done
}

isalive_check() 
{
    echo "=> Running OpenAM alive.jsp check"
    STATUS_CODE="503"
    until [ "${STATUS_CODE}" = "200" ]; do
        echo "=> ${AM_URL} is not alive, waiting 10 seconds before retry..."
        sleep 10
        STATUS_CODE=$(curl -LI  http://${AM_URL}/openam/isAlive.jsp \
          -o /dev/null -w '%{http_code}\n' -s)
    done
    echo "=> OpenAM is alive"
}

livecheck_stage1() 
{
    # This livecheck waits for OpenAM config to be imported.
    # We are looking to amster pod logs periodically.
    echo "=> Livecheck stage1 - waiting for config to be imported to OpenAM";
    sleep 10
    AMSTER_POD_NAME=$(kubectl get pods --selector=app=amster-${NAMESPACE}-amster \
        -o jsonpath='{.items[*].metadata.name}')
    FINISHED_STRING="Configuration script finished"

    while true; do
    OUTPUT=$(kubectl logs ${AMSTER_POD_NAME} amster)
        if [[ $OUTPUT = *$FINISHED_STRING* ]]; then
            echo "=> OpenAM configuration import is finished"
            break
        fi
        echo "=> Configuration not finished yet. Waiting for 10 seconds...."
        sleep 10
    done
}

restart_openam() 
{
    # We need to restart OpenAM to take CTS settings online
    OPENAM_POD_NAME=$(kubectl get pods --selector=app=openam \
        -o jsonpath='{.items[*].metadata.name}')
    kubectl delete pod $OPENAM_POD_NAME --namespace=${NAMESPACE}
    sleep 10
    isalive_check
    printf "\e[38;5;40m=> Deployment is now ready\n"
}


# All helm chart paths are relative to this directory.
DIR=`echo $(dirname "$0")/..`

parse "$@"
chk_config

# Dryrun? Just show what helm commands would be executed.
if [ ! -z "$DRYRUN" ]; then
    deploy_charts 
    exit 0
fi

create_namespace
deploy_charts
livecheck_stage1
restart_openam