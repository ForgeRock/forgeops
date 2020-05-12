#!/usr/bin/env bash
[[ "${FR_DEBUG}" == true ]] && set -x
rsync -War /opt/build/ /opt/workspace
if ! "${HOME}/.local/bin/bootstrap-project.sh" run-bootstrap;
then
    echo "failed to bootstrap project";
    exit 1
fi
echo "${SSH_PUBKEY}" >> ~/.ssh/authorized_keys
printenv >> ~/.ssh/environment
exec /usr/sbin/sshd -D -p "${SSH_PORT}" -f ~/etc/sshd_config
# exec pause
