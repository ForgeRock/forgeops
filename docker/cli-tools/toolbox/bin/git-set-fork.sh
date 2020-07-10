#!/usr/bin/env bash
# This is run inside of the toolbox container to set the origin to the users github fork of forgeops
WORKSPACE="${WORKSPACE:-/opt/workspace}"

usage() {
  echo "Usage:  $0 git-ssh-url"
  echo "Example"
  echo "$0 git@github.com:myrepo/forgeops.git"
}

keygen() {
  mkdir -p ~/.ssh "${WORKSPACE}/.ssh"
  ssh-keygen -b 4096 \
    -C "ForgeOps toolbox deployment key" \
    -t ed25519 \
    -f "${WORKSPACE}/.ssh/id_rsa"
  cat <<EOF >"$HOME/.ssh/config"
host github.com
    HostName github.com
    IdentityFile $WORKSPACE/.ssh/id_rsa
    User git
EOF
  echo "configure your git repo to accept pushes from this public key:"
  cat "${WORKSPACE}/.ssh/id_rsa.pub"
  echo ""
  echo ""
  echo "this key is destroyed with the PVC, its recommended that this key be configured with limited access like a deploy key: https://developer.github.c
om/v3/guides/managing-deploy-keys/"
}

if [ ! -d "$WORKSPACE" ]; then
  echo "This tool is designed to be run in the toolbox. Exiting"
  exit 1
fi

[ $# -ne 1 ] && usage

keygen
cd "$WORKSPACE/forgeops" || exit 1

git remote add origin "$1"

