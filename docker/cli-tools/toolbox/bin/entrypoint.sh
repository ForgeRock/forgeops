#!/usr/bin/env bash
[[ "${FR_DEBUG}" == true ]] && set -x

WORKSPACE="${WORKSPACE:-/opt/workspace}"
cd $WORKSPACE

if [[ ! -f "${WORKSPACE}/.CONFIGURED" ]];
then
  echo "Configuring workspace"
  git clone --origin upstream --depth 1 https://github.com/ForgeRock/forgeops.git
  cp -r /opt/build/* .
  touch "${WORKSPACE}/.CONFIGURED"
  echo "done"
fi

echo "Starting dev environment"
start-dev.sh


# The pod should execute with args: ["pause"]
exec $*
