#!/usr/bin/env bash

SCRIPT_NAME="$(basename "$0")"

if ! command -v kustomize >/dev/null 2>&1;
then
    echo "kustomize binary required"
fi

if ! command -v kubectl >/dev/null 2>&1;
then
    echo "kubectl binary required"
fi

usage () {
read -r -d '' help <<-EOF

ForgeOps Toolbox CLI

A wrapper script for deploying the ForgeOps toolkit inside a cluster.

This script generates a kustomize profile, and then deploys the toolbox.

Usage:  ${SCRIPT_NAME} [OPTIONS] COMMAND

Command:
    deploy     deploys forgeops-toolbox and makes sure kaniko secret is available
    configure  generates a ./forgeops-toolbox/kustomization.yaml file
    remove     *destructive* removes all objects (including PVC) related to the toobox
    all        configures and deploys

Options:
    -n         namespace for deployment (default: active namespace)
    -s         subdomain utilized by ForgeRock platform (default: iam)
    -d         domain utilized by ForgeRock platform (default: example.com)
    -f         git repository used as the fork of forgeops
    -r         docker repository to push images from the kubernetes cluster (default: gcr.io/engineering-devops)
    -i         ssh public key used for ssh connection with VS Code Remote Development
    -h         help

Examples:
    # using defaults configure and deploy
    ${SCRIPT_NAME} -f https://github.com/mygithuborg/forgeops.git all
    # change defaults, configure kustomization.yaml
    ${SCRIPT_NAME} -r dockerhub.com/mydockerhubaccount
                   -s example-subdomain
                   -d mydomain.com
                   -n mynamespace
                   -f https://github.com/mygithuborg/forgeops.git
                   -i ~/.ssh/id_rsa.pub
                   configure
    # deploys kustomization
    ${SCRIPT_NAME} deploy
    # cleanup - careful this removes even volumes which could result in lost work
    ${SCRIPT_NAME} remove
EOF
    printf "%-10s" "$help"
}

load_ns () {
    ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' | tr -d '\n')
    if [[ "${ns}" == "" ]];
    then
        # return nothing validation will throw error
        return 1
    fi
    echo "${ns}"
}

run_configure () {
    missing_opts=0
    for req in NAMESPACE SUBDOMAIN DOMAIN FORK DOCKER_REPO;
    do
        if [[ "${!req}" == "" ]];
        then
            echo "${req} is required";
            missing_opts=1
        fi
    done
    if (( "${missing_opts}" != 0 ));
    then
        usage;
        return 1
    fi
    if [ ! -z ${SSH_PUBKEY+x} ] && [[ ! -f "${SSH_PUBKEY}" ]];
    then
        echo "a path to a public key is required"
        return 1
    elif [ ! -z ${SSH_PUBKEY+x} ];
    then
        SSH_PUBKEY=$(cat $SSH_PUBKEY)
    fi
    mkdir -p forgeops-toolbox
    cat <<KUSTOMIZATION >forgeops-toolbox/kustomization.yaml
namespace: ${NAMESPACE}
resources:
- github.com/ForgeRock/forgeops//kustomize/base/toolbox/
patches:
  - patch: |-
      kind: Deployment
      metadata:
        name: toolbox
      spec:
        template:
          spec:
            containers:
              - name: toolbox
                env:
                - name: FR_NAMESPACE
                  value: ${NAMESPACE}
                - name: FR_SUBDOMAIN
                  value: ${SUBDOMAIN}
                - name: FR_DOMAIN
                  value: ${DOMAIN}
                - name: FR_FORK
                  value: ${FORK}
                - name: FR_DOCKER_REPO
                  value: ${DOCKER_REPO}
                - name: SSH_PUBKEY
                  value: ${SSH_PUBKEY}
    target:
      kind: Deployment
      name: toolbox
KUSTOMIZATION
    if ! k8s get ns "${NAMESPACE}";
    then
        echo "${NAMESPACE} not found, attempting to create"
        if ! k8s create ns "${NAMESPACE}";
        then
            echo "Couldn't create ${NAMESPACE}, exiting"
            return 1;
        fi
        echo "${NAMESPACE} created!";
    fi
    if ! k8s config set-context --current --namespace=${NAMESPACE};
    then
        echo "couldn't set context to ${NAMESPACE}";
    fi
    if ! k8s get secret kaniko-secret;
    then
        echo "kaniko secret doesn't exist please create it"
        echo "hint: https://github.com/GoogleContainerTools/kaniko#running-kaniko-in-a-kubernetes-cluster"
        return 1
    fi
    return 0
}

# surpress kubectl output
k8s () {
    if ! kubectl "${@}" > /dev/null 2>&1;
    then
        return 1
    fi
}

run_deploy () {
    if ! kustomize build forgeops-toolbox | k8s -n "${NAMESPACE}" apply -f -;
    then
        echo "failed to deploy toolbox";
        return 1
    fi
    if ! k8s wait --for=condition=available deployment/forgeops-cdk-toolbox --timeout=300s -n "${NAMESPACE}";
    then
        echo "toolbox never reached status of available"
        return 1
    fi
    echo "deployed forgeops-toolbox"
    echo "to get started run:"
    echo "  kubectl exec -it deploy/forgeops-cdk-toolbox tmux"
    return 0
}

run_delete () {
    kustomize build forgeops-toolbox | k8s -n "${NAMESPACE}" delete -f -
    return $?
}

NAMESPACE=$(load_ns)
SUBDOMAIN=iam
DOMAIN=example.com
DOCKER_REPO=gcr.io/engineering-devops

# arg/opt parse
while getopts n:s:d:f:r:i:h option
do
    case "${option}"
        in
        n) NAMESPACE=${OPTARG};;
        s) SUBDOMAIN=${OPTARG};;
        d) DOMAIN=${OPTARG};;
        f) FORK=${OPTARG};;
        r) DOCKER_REPO=${OPTARG};;
        i) SSH_PUBKEY=${OPTARG};;
        h) usage; exit 0;;
        *) usage; exit 1;;
    esac
done
shift $((OPTIND - 1))

if [[ "$#" != 1 ]];
then
    echo "one argument is expected"
    exit 1
fi

while (( "$#" )); do
    case "$1" in
        configure)
            shift
            run_configure
            exit $?
            ;;
        deploy)
            shift
            run_deploy
            exit $?
            ;;
        remove)
            shift
            run_delete
            exit $?
            ;;
        all)
            run_configure && run_deploy
            exit $?
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
usage
exit 1
