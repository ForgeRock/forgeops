#!/usr/bin/env bash
env_vars=()
volumes=()
sdks=()
mount_root=/opt/forgeops/mnt


usage() {

read -r -d '' help <<-EOF

ForgeOps CLI

A wrapper that executes ForgeOps tools inside a container.

All state is kept on the host and in default location for the tool such as ~/.config/gcloud.

The container has full access to credentials utilized by the tools.

Usage:  cli.sh MODE [OPTIONS] COMMAND

Mode:
    cdm     Environment required to run Cloud Deployment Model
    cdk     Environment required to run Cloud Development Kit

Options:
--build-env     docker daemon and registry to use for builds (only for CDK)
                (default: minikube|localhost)

Examples:
    # list stack resources
    cli.sh cdm pulumi stack ls
    # deploy to minikube
    cli.sh cdk skaffold dev
    # build using localhost dockerd, run on some remote cluster
    cli.sh cdk --build-env localhost skaffold build && cli.sh cdk --build-env localhost skaffold run

Environment Variables:
   CDM_IMAGE    CDM container to run
   CDK_IMAGE    CDK container to run

EOF

    printf "%-10s" "$help"
}

_add_volume() {
    volumes+=( "-v" "${1}" )
}

_add_env() {
    env_vars+=( "-e" "${1}" )
}

_add_sdk() {
    sdks+=( "${1}" )
}

_config_gcloud() {
    if [[ -z "${GOOGLE_CLOUD_PROJECT}" ]];
    then
       echo "GOOGLE_CLOUD_PROJECT environment variable required"
       exit 1;
    fi
    _add_volume "${HOME}/.config/gcloud/:${mount_root}/.config/gcloud/"
    _add_env "GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}"
    _add_sdk "gcp"
    if [[ "${CLI_MODE}" == "cdk" ]];
    then
        [[ ! -f "${HOME}/.config/gcloud/application_default_credentials.json" ]] \
            && echo "using GCP and CDK requires application credentials to be set: gcloud auth application-default login" \
                && exit 1
        _add_env 'GOOGLE_APPLICATION_CREDENTIALS=/opt/forgeops/mnt/.config/gcloud/application_default_credentials.json'
    fi

}

_config_aws() {
    _add_volume "${HOME}/.aws/:${mount_root}/.aws/"
    _add_sdk "aws"
}

_config_azure() {
    _add_volume "${HOME}/.azure/:${mount_root}/.azure/"
    _add_sdk "azure"
}

_config_pulumi() {
    [[ ! -d "${HOME}/.pulumi" ]] \
        && echo "No pulumi home detected. Creating ~/.pulumi" \
            && mkdir -p ~/.pulumi \
                && echo "{}" > ~/.pulumi/credentials.json
    [[ -z "${PULUMI_CONFIG_PASSPHRASE}" ]] \
        && echo "Please set the environment variable PULUMI_CONFIG_PASSPHRASE" \
            && exit 1
    _add_env "PULUMI_CONFIG_PASSPHRASE=${PULUMI_CONFIG_PASSPHRASE}"
    _add_volume "${HOME}/.pulumi/backups:${mount_root}/.pulumi/backups"
    _add_volume "${HOME}/.pulumi/history:${mount_root}/.pulumi/history"
    _add_volume "${HOME}/.pulumi/stacks:${mount_root}/.pulumi/stacks"
    _add_volume "${HOME}/.pulumi/credentials.json:${mount_root}/.pulumi/credentials.json"
    _add_volume "${HOME}/.pulumi/workspaces:${mount_root}/.pulumi/workspaces"
}

_config_cloud_sdk() {
    [[ -d "${HOME}/.aws" ]] \
        && _config_aws
    [[ -d "${HOME}/.azure" ]] \
        && _config_azure
    [[ -d "${HOME}/.config/gcloud" ]] \
        && _config_gcloud
    [[ ${#sdks[@]} -eq 0 ]] \
        && echo "No cloud provider SDK config found, please create one e.g. ~/.aws ~/.azure ~/.config/gcloud" \
            && exit 1
}


_set_minikube() {
    local docker_host
    docker_host=$(minikube ip)
    _add_env 'DOCKER_TLS_VERIFY="1"'
    _add_env "DOCKER_HOST=tcp://${docker_host}:2376"
    _add_env "DOCKER_CERT_PATH=${mount_root}/.certs"
    _add_volume "$HOME/.minikube/certs:${mount_root}/.certs"
}

_set_localhost() {
    #_add_volume "${HOME}/.docker:${mount_root}/.docker"
    _add_volume "/var/run/docker.sock:/var/run/docker.sock"
    _config_cloud_sdk

}

_pre_exec() {
    if [[ "${CDM_DEBUG}" == "true" ]];
    then
        set -x
        _add_env "CDM_DEBUG=true"
    fi
    LOCALDIR=$(pwd)
    USERID=$(id -u)
    GROUPID=$(id -g)
    _add_volume "${LOCALDIR}:${mount_root}/ctx"
}

run_cdm() {
    _config_pulumi
    _config_cloud_sdk
    local cli_image="${CDM_IMAGE:-gcr.io/engineering-devops/cdm-cli:latest}"
    kubeconfig="${KUBECONFIG:-$HOME/.kube/config}"
    _add_volume "${kubeconfig}:${mount_root}/.kube/config"
    run "${cli_image}" "${@}"
}

run_cdk() {
    local cli_image="${CDK_IMAGE:-gcr.io/engineering-devops/cdk-cli:latest}"
    local build_env=$2
    if [[ $1 == "--build-env" ]];
    then
        case ${build_env} in
            minikube)
                _set_minikube
                shift 2
                ;;
            localhost) # end argument parsing
                _set_localhost
                shift 2
                ;;
            *)
                echo "unknown build-env value"
                usage
                exit 1
                ;;
        esac;
    else
        _set_minikube;
    fi

    local skaf_home
    skaf_home=$HOME/.skaffold
    [[ ! -d "${skaf_home}" ]] \
        && mkdir -p "${skaf_home}"

    kubeconfig="${KUBECONFIG:-$HOME/.kube/config}"
    _add_volume "${skaf_home}:${mount_root}/.skaffold"
    _add_volume "${kubeconfig}:${mount_root}/.kube/config"
    run "${cli_image}" "${@}"
}

run() {
    local cli_image=$1
    shift
    _pre_exec
    # shellcheck disable=SC2086
    exec docker run --rm  \
                    ${volumes[*]} \
                    ${env_vars[*]} \
                    -it "${cli_image}" "${USERID}" "${GROUPID}" "${LOCALDIR}" "${@}"
}


while (( "$#" )); do
    case "$1" in
        cdk)
            shift
            CLI_MODE=cdk
            # shellcheck disable=SC2068
            run_cdk ${@}
            exit
            ;;
        cdm)
            shift
            CLI_MODE=cdm
            # shellcheck disable=SC2068
            run_cdm ${@}
            exit
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
usage
exit 1
