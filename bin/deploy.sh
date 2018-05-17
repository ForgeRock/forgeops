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

print_help()
{
    printf 'Usage: \t%s\t[-c|--cfgdir <cfg directory>] [-n|--namespace <namespace>] [-d|--domain <domain>]
            \t\t [-p|--prefix <AM prefix>] [-f|--yaml <common yaml file>] [--remove-all] [-h|--help]\n' "$0"
    printf 'Example 1: %s -p openam -n dev -d forgerock.org\n' "$0"
    printf 'Example 2: %s -c samples/config/dev\n' "$0"
}

parse_commandline()
{
    while test $# -gt 0
    do
        case "$1" in
            -c|--cfgdir)
                CFGDIR="$2"
                shift
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift
                ;;
            -d|--domain)
                DOMAIN="$2"
                shift
                ;;
            -p|--prefix)
                URL_PREFIX="$2"
                shift
                ;;
            -f|--yaml)
                YAML="$2"
                shift
                ;;
            -s|--silent)
                SILENT=true
                ;;
            --remove-all)
                RMALL=true
                ;;
            -h|--help|*)
                print_help
                exit 0
                ;;
        esac
        shift
    done
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
        source ${CFGDIR}/env.sh
        if [ $? != 0 ]; then
            echo "ERROR: Could not find or read your env.sh file.  Exiting!"
            exit 1
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



#### Setup methods
#set_kubectl_context() 
#{
#    if [ -z ${CONTEXT} ]; then
#        CONTEXT=$(kubectl config current-context)
#    fi
#    echo "=> Switching Context to \"${CONTEXT}\" and Namespace to \"${NAMESPACE}\""
#    kubectl config use-context ${CONTEXT} --namespace=${NAMESPACE}
#    if test $? -gt 0
#        then
#            echo "=> Could not use context \"${CONTEXT}\". Make sure context exists. Exiting!!!"
#        exit 1
#    fi
#}

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
    # These are the charts (components) that will be deployed via helm 
    for comp in ${COMPONENTS[@]}; do
        chart="${comp}"
        case "${comp}" in
          *store)
            chart="opendj"
            ;;
        esac

        if [ ! -z ${YAML} ]; then
            common="-f ${YAML}"
        else
            common="-f ${CFGDIR}/common.yaml"
        fi

        # if nothing then there is no commons.yaml
        if [ ! -f "${common}" ]; then
            common=""
        fi

        helm install --name ${comp}-${NAMESPACE} ${common} -f ${CFGDIR}/${comp}.yaml \
            --namespace=${NAMESPACE} helm/${chart}
    done
}

isalive_check() 
{
    echo "=> Running OpenAM alive.jsp check"
    STATUS_CODE="503"
    until [ "${STATUS_CODE}" = "200" ]; do
        echo "=> AM is not alive, waiting 10 seconds before retry..."
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




############################## Main method ############################



# Make sure we are in the root directory. All paths are relative to this directory.
cd "$(dirname "$0")/.." 

parse_commandline "$@"
chk_config
create_namespace
deploy_charts
livecheck_stage1
restart_openam
