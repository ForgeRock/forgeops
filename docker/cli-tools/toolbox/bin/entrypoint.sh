#!/usr/bin/env bash
[[ "${FR_DEBUG}" == true ]] && set -x

cd $WORKSPACE

if [[ ! -f "${WORKSPACE}/.CONFIGURED" ]];
then
  echo "Configuring workspace"
  git clone --origin upstream --depth 1 https://github.com/ForgeRock/forgeops.git
  (cd /opt/build; tar cf - .) | tar xvf -
  touch "${WORKSPACE}/.CONFIGURED"
fi

# TODO: Needed still?
#echo "${SSH_PUBKEY}" >> ~/.ssh/authorized_keys
#printenv >> ~/.ssh/environment

# Needed for VSCode remote support
#exec /usr/sbin/sshd -D -p "${SSH_PORT}" -f ~/etc/sshd_config
# Need for VSCode
exec /usr/sbin/sshd -D -p "${SSH_PORT}"

exec pause
