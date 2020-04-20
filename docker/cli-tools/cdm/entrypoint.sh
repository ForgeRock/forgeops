#!/usr/bin/env bash

function prep_helm() {
    tiller &>> /dev/null &
    export HELM_HOST=localhost:44134;
}

ARGS=(${entry_args[@]:3})
if [[ "${CDM_DEBUG}" == "true" ]];
then
    set -x;
fi
umask 0002
entry_args=("${@}")
userid=${entry_args[0]}
groupid=${entry_args[1]}
homedir=/opt/forgeops/mnt
getent group ${groupid} > /dev/null 2>&1 || groupmod -g ${groupid} forgeops
usermod --uid ${userid} --gid ${groupid} forgeops
# These two paths aren't directly mounted, so they must have the ownership changed
chown forgeops:forgeops /opt/forgeops/mnt/{.pulumi,.config}
export HOME=${homedir}
export PULUMI_HOME=/opt/forgeops/mnt/.pulumi
export NODE_PATH=/opt/forgeops/usr/node_modules
# Set the directory for the program we are to run e.g. gcp/infra || gcp/gke
if [[ "${entry_args[3]}" == "pulumi" ]];
then
    localhost_dir="${entry_args[2]}"
    program=$(basename ${localhost_dir})
    provider=$(basename $(dirname "${localhost_dir}"))
    pulumi_prgrm="/opt/forgeops/usr/${provider}/${program}"
    PULUMI_ARGS=( "-C" "${pulumi_prgrm}" )
    ARGS=( pulumi ${PULUMI_ARGS[@]} ${entry_args[@]:4} )
    if [[ "${entry_args[4]}" == "up" || "${entry_args[4]}" == "update" ]];
    then
        stack_name=$(setpriv --reuid=${userid} --regid=${groupid} --groups 360360,998 --inh-caps=-all  pulumi -C "${pulumi_prgrm}" stack ls --json | jq -r '.[] | select(.current == true) | .name')
        stack_file="/opt/forgeops/mnt/ctx/Pulumi.${stack_name}.yaml"
        ARGS=( ${ARGS[@]} "--config-file" "${stack_file}" );
    fi
elif [[ "${entry_args[3]}" == "addons-deploy.sh" ]];
then
    prep_helm
    ARGS=(${entry_args[@]:3})
elif [[ "${entry_args[3]}" == "ingress-controller-deploy.sh" ]];
then
    prep_helm
    ARGS=(${entry_args[@]:3})
elif [[ "${entry_args[3]}" == "prometheus-deploy.sh" ]];
then
    prep_helm
    ARGS=(${entry_args[@]:3})
else
    ARGS=(${entry_args[@]:3})
fi
# Add supplemental group such that permissions are g=r-x files/exec
exec setpriv --reuid=${userid} --regid=${groupid} --groups 360360,998 --inh-caps=-all ${ARGS[@]}
