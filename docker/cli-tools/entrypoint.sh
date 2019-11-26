#!/usr/bin/env bash
umask 0002
entry_args=("${@}")
userid=${entry_args[0]}
groupid=${entry_args[1]}
homedir=/opt/forgeops/mnt
# Set the directory for the program we are to run e.g. gcp/infra || gcp/gke
if [[ "${entry_args[3]}" == "pulumi" ]];
then
    localhost_dir="${entry_args[2]}"
    program=$(basename ${localhost_dir})
    provider=$(basename $(dirname "${localhost_dir}"))
    pulumi_prgrm="${provider}/${program}"
    PULUMI_ARGS=( "-C" "/opt/forgeops/usr/${pulumi_prgrm}" )
    ARGS=( pulumi ${PULUMI_ARGS[@]} ${entry_args[@]:4} )
else
    ARGS=(${entry_args[@]:3})
fi
groupmod -g ${groupid} forgeops
usermod --uid ${userid} --gid ${groupid} forgeops
# These two paths aren't directly mounted, so they must have the ownership changed
chown forgeops:forgeops /opt/forgeops/mnt/{.pulumi,.config}
export HOME=${homedir}
export PULUMI_HOME=/opt/forgeops/mnt/.pulumi
export NODE_PATH=/opt/forgeops/usr/node_modules
# Add supplemental group such that permissions are g=r-x files/exec
exec setpriv --reuid=${userid} --regid=${groupid} --groups 360360 --inh-caps=-all ${ARGS[@]}
