#!/bin/bash
################################################################################
# This script will do following:
#   - Deploy OpenAM along with DS (configstore, userstore and CTS)
#   - Ensure configs are in place
#   - Restart OpenAM to take all configuration online
################################################################################


#### Variables

NAMESPACE="bench"
DOMAIN="frk8s.net"
URL_PREFIX="openam"
TYPE="m-cluster"


# Note the above variables are intended to be overwritten if cmd line args are provided 

print_help()
{
    printf 'Usage: \t%s\t[-c|--context <context>] [-n|--namespace <namespace>] [-d|--domain <domain>]
            \t\t[-p|--prefix <AM prefix>] [-t|--type <s-cluster|m-cluster>] [-h|--help]\n' "$0"
    printf 'Example: ./deploy.sh -c dev-cluster -n dev -d forgerock.org -p openam -t m-cluster\n'
}

parse_commandline()
{
    while test $# -gt 0
    do
        case "$1" in
            -c|--context)
                CONTEXT="$2"
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
            -t|--type)
                TYPE="$2"
                shift
                ;;
            -h|--help|*)
                print_help
                exit 0
                ;;
        esac
        shift
    done
}

AM_URL="${URL_PREFIX}.${NAMESPACE}.${DOMAIN}"

#### Setup methods
set_kubectl_context() 
{
    if [ -z ${CONTEXT} ]; then
        CONTEXT=$(kubectl config current-context)
    fi

    echo "=> Switching Context to \"${CONTEXT}\" and Namespace to \"${NAMESPACE}\""

    kubectl config use-context ${CONTEXT} --namespace=${NAMESPACE}
    
    if test $? -gt 0
        then
            echo "=> Could not use context \"${CONTEXT}\". Make sure context exists. Exiting!!!"
        exit 1
    fi
}


#### Deploy methods
deploy_charts() 
{
    echo "=> Deploying charts into namespace \"${NAMESPACE}\""
    # Update openam chart dependencies
    helm dep up ../../helm/openam

    # These are the charts (components) that will be deployed via helm
    components=(frconfig configstore userstore ctsstore openam amster)

    for c in ${components[@]}; do
        helm install --name ${c}-${NAMESPACE} -f type/common.yaml -f type/${TYPE}/${c}.yaml \
            --namespace=${NAMESPACE} ../../helm/${c}
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

#### Main method
parse_commandline "$@"
set_kubectl_context
deploy_charts
livecheck_stage1
restart_openam
