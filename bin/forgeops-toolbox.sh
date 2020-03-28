#!/usr/bin/env bash

run_configure () {
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
        echo "couldnt set context to ${NAMESPACE}";
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
    kubectl "${@}" > /dev/null 2>&1
    return $?
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


# check for deps
if ! which kubectl > /dev/null 2>&1;
then
    echo "kubectl not found in path"
    exit 1;
fi
if ! which kustomize > /dev/null 2>&1;
then
    echo "kustomize not found in path"
    exit 1;
fi

# arg/opt parse
while getopts n:s:d:f:r:h option
do
    case "${option}"
        in
        n) NAMESPACE=${OPTARG};;
        s) SUBDOMAIN=${OPTARG};;
        d) DOMAIN=${OPTARG};;
        f) FORK=${OPTARG};;
        r) DOCKER_REPO=${OPTARG};;
        h) usage; exit 0;;
        *) usage; exit 1;;
    esac
done
shift $((OPTIND - 1))

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
    esac
done
