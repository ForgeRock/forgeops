#!/usr/bin/env bash
cat ~/.etc/BANNER.txt

cd ${WORKSPACE} || exit 1

if [[ ! -f "${WORKSPACE}/.CONFIGURED" ]];
then
    read -r -d '' needs_boot <<-EOF

Welcome to the ForgeOps toolbox!

You'll find a recent clone of the ForgeOps git repository in the current working directory.

You should begin by bootstrapping your workspace using the boostrap-project.sh tool.

Example:
$ bootstrap-project.sh run-bootstrap

More:
$ bootstrap-project.sh -h

You'll need a deployment key if you haven't generated one yet, this should be added to your forked repo as a deployment key with read/write access

Example:
$ bootstrap-project.sh regenerate-deploy-key

To deploy the ForgeRock platform:
$ ./dev/run.sh

EOF
printf "%-10s \n\n" "$needs_boot"
else
    read -r -d '' running <<-EOF
Welcome to the ForgeOps toolbox!

You'll need a deployment key if you haven't generated one yet, this should be added to your forked repo as a deployment key with read/write access

Generate a key:
$ bootstrap-project.sh regenerate-deploy-key

To deploy the ForgeRock platform:
$ ./dev/run.sh

EOF
printf "%-10s \n\n" "$running"

fi
