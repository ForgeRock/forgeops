#!/usr/bin/env bash

echo "${GIT_KEY}" > ~/.gitkey
chmod 0600 ~/.gitkey
echo "setting up key"
export GIT_SSH_COMMAND="ssh -o 'StrictHostKeyChecking=no' -i $HOME/.gitkey"
