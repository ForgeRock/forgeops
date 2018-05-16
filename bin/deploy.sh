#!/bin/bash
# Deployment script that can be used for CI automation, etc.
# This script assumes that kubectl and helm are available, and have been configured
# with the correct context for the cluster.
# Warning: This script will purge any existig deployments in the target namespace!


configDir=$1

if [ -z "${configDir}" ] || [ ! -d ${configDir} ];
then 
    echo "Usage: dep.sh config-directory"
    exit 1
fi

# Make sure we are in the directory where the script is located. All paths are relative to this directory.

cd "$(dirname "$0")/.."
helm_dir=helm 

# Source the environment specific parameters for this deployment.
source ${configDir}/env.sh

if [ -z "${NAMESPACE}" ]; 
then
    echo "Error: It looks like your env.sh does not set the namespace for the deployment."
    exit 1
fi


echo "Cleaning up any previous deployments. Ignore errors below"
bin/remove-all.sh ${NAMESPACE}

echo "Creating namespace ${NAMESPACE}. Ignore errors below it if already exists"
kubectl create namespace ${NAMESPACE}
# Note the above variables are intended to be overwritten if cmd line args are provided 

URL_PREFIX=openam

AM_URL="${URL_PREFIX}.${NAMESPACE}.${DOMAIN}"

# todo: this should decode and install any secrets we need. The git-ssh-key, for example
create_secrets() 
{
    echo "to do"
}

#### Deploy. Args:  $1 - the directory that holds our configuration files
deploy_charts() 
{
    echo "=> Deploying charts into namespace ${NAMESPACE}"

    cdir=$1
    # These are the charts (components) that will be deployed via helm
    #components=(frconfig configstore userstore ctsstore openam amster)

    for c in ${COMPONENTS[@]}; do

        chart="${c}"
        
        case "${c}" in
          *store)
            chart="opendj"
            ;;
        esac

        helm install --name ${c}-${NAMESPACE} -f ${cdir}/common.yaml -f ${cdir}/${c}.yaml \
            --namespace=${NAMESPACE}  ${helm_dir}/${chart}

    done

}

isalive_check() 
{
    echo "=> Running OpenAM alive.jsp check"
    STATUS_CODE="503"
    until [ "${STATUS_CODE}" = "200" ]; do
        echo "=> AM ${AM_URL} is not alive, waiting 10 seconds before retry..."
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
        --namespace ${NAMESPACE} \
        -o jsonpath='{.items[*].metadata.name}')
    FINISHED_STRING="Configuration script finished"

    while true; do
    OUTPUT=$(kubectl logs ${AMSTER_POD_NAME} --namespace ${NAMESPACE} amster)
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
        --namespace "${NAMESPACE}" \
        -o jsonpath='{.items[*].metadata.name}')
    kubectl delete pod $OPENAM_POD_NAME --namespace="${NAMESPACE}"
    sleep 10
    isalive_check
    printf "\e[38;5;40m=> Deployment is now ready\n"
}

#### Main method
deploy_charts "${configDir}"
livecheck_stage1
restart_openam
