#!/usr/bin/env bash
umask 0002
entry_args=("${@}")
userid=${entry_args[0]}
groupid=${entry_args[1]}
homedir=/opt/forgeops/mnt
getent group ${groupid} > /dev/null 2>&1 || groupmod -g ${groupid} forgeops
usermod --uid ${userid} --gid ${groupid} forgeops
export HOME=${homedir}
ARGS=(${entry_args[@]:3})
# Add supplemental group such that permissions are g=r-x files/exec
exec setpriv --reuid=${userid} --regid=${groupid} --groups 360360,998 --inh-caps=-all ${ARGS[@]}
