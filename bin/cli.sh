#!/usr/bin/env bash

CLI_IMAGE="${CLI_IMAGE:-gcr.io/engineering-devops/forgeops-cli:latest}"
[[ -z "${PULUMI_CONFIG_PASSPHRASE}" ]] \
    && echo "Please set the environment variable PULUMI_CONFIG_PASSPHRASE" \
        && exit 1

sdk_config_volumes=()
[[ -d "${HOME}/.aws" ]] \
    && sdk_config_volumes+=( "-v" "${HOME}/.aws/:/opt/forgeops/.aws/" )
[[ -d "${HOME}/.azure" ]] \
    && sdk_config_volumes+=( "-v" "${HOME}/.azure/:/opt/forgeops/.azure/" )
[[ -d "${HOME}/.config/gcloud" ]] \
    && sdk_config_volumes+=( "-v" "${HOME}/.config/gcloud:/opt/forgeops/.config/gcloud" )

[[ ${#sdk_config_volumes[@]} -eq 0 ]] \
    && echo "No cloud provider SDK config found, please create one e.g. ~/.aws ~/.azure ~/.config/gcloud" \
        && exit 1

[[ ! -d "${HOME}/.pulumi" ]] \
    && echo "No pulumi home detected. Creating ~/.pulumi" \
        && mkdir -p ~/.pulumi

LOCALDIR=$(pwd)
USERID=$(id -u)
GROUPID=$(id -g)
# mount and run
docker pull "${CLI_IMAGE}"
exec docker run --rm  \
                ${sdk_config_volumes[*]} \
                -v "${HOME}/.pulumi/:/opt/forgeops/.pulumi/" \
                -v "${LOCALDIR}:/opt/forgeops/local" \
                -e "PULUMI_CONFIG_PASSPHRASE=${PULUMI_CONFIG_PASSPHRASE}" \
                -it "${CLI_IMAGE}" ${USERID} ${GROUPID} ${LOCALDIR} ${@}
