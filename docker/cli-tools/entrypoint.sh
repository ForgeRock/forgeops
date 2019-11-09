#!/usr/bin/env bash
export PATH="$PATH:/usr/local/google-cloud-sdk/bin"
export NODE_PATH="/opt/forgeops/usr/node_modules"
echo "export PS1=forgeopscli▶ " >> /opt/forgeops/.bashrc
entry_args=("${@}")
userid=${entry_args[0]}
groupid=${entry_args[1]}
# set the directory for the program we are to run e.g. gcp/infra || gcp/gke
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
# drop to the same uid/gid as host
HOME=/opt/forgeops
usermod --uid ${userid} --gid ${groupid} forgeops 2&> /dev/null
find ${HOME} . -type d -name "usr" -prune -o -type f -print | xargs chown -R ${userid}:${groupid}
# add supplimental group to rx nodejs scripts
exec setpriv --reuid=${userid} --regid=${groupid} --groups 360360 --inh-caps=-all ${ARGS[@]}
