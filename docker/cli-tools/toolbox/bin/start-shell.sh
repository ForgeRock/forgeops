#!/usr/bin/env bash
cat ~/etc/BANNER.txt

cd ${WORKSPACE} || exit 1

if [[ ! -f "${WORKSPACE}/.CONFIGURED" ]];
then
    read -r -d '' needs_boot <<-EOF

Welcome to the ForgeOps toolbox!

You'll find a recent clone of the ForgeOps git repository in the current working directory.

You should begin by bootstrapping your workspace by running the bin/create-dev.sh script.

If you want to add your fork of the forgeops repository, see the bin/git-set-fork.sh command.

EOF

printf "%-10s \n\n" "$running"

fi
