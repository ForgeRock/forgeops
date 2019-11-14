#!/usr/bin/env bash
env_vars=()
volumes=()
sdks=()


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
    _add_volume "${HOME}/.config/gcloud:/opt/forgeops/.config/gcloud"
    _add_env "GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}"
    _add_sdk "gcp"
}

_config_aws() {
    _add_volume "${HOME}/.aws/:/opt/forgeops/.aws/"
    _add_sdk "aws"
}

_config_azure() {
    _add_env "${HOME}/.azure/:/opt/forgeops/.azure/"
    _add_sdk "azure"
}

_config_pulumi() {
    [[ ! -d "${HOME}/.pulumi" ]] \
        && echo "No pulumi home detected. Creating ~/.pulumi" \
            && mkdir -p ~/.pulumi \
                && touch ~/.pulumi/credentials.json
    [[ -z "${PULUMI_CONFIG_PASSPHRASE}" ]] \
        && echo "Please set the environment variable PULUMI_CONFIG_PASSPHRASE" \
            && exit 1
    _add_env "PULUMI_CONFIG_PASSPHRASE=${PULUMI_CONFIG_PASSPHRASE}"
    _add_volume "${HOME}/.pulumi/backups:/opt/forgeops/.pulumi/backups"
    _add_volume "${HOME}/.pulumi/history:/opt/forgeops/.pulumi/history"
    _add_volume "${HOME}/.pulumi/stacks:/opt/forgeops/.pulumi/stacks"
    _add_volume "${HOME}/.pulumi/credentials.json:/opt/forgeops/.pulumi/credentials.json"
    _add_volume "${HOME}/.pulumi/workspaces:/opt/forgeops/.pulumi/workspaces"
}

_config_sdk() {
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

_pre_exec() {
    LOCALDIR=$(pwd)
    USERID=$(id -u)
    GROUPID=$(id -g)
    CLI_IMAGE="${CLI_IMAGE:-gcr.io/engineering-devops/forgeops-cli:latest}"
    _add_volume "${LOCALDIR}:/opt/forgeops/local";
}

_config_pulumi
_config_sdk
_pre_exec

# mount and run
docker pull "${CLI_IMAGE}"
exec docker run --rm  \
                ${volumes[*]} \
                ${env_vars[*]} \
                -it "${CLI_IMAGE}" ${USERID} ${GROUPID} ${LOCALDIR} ${@}
