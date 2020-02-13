#!/usr/bin/env bash
cat ~/.etc/BANNER.txt

if [[ ! -f "${WORKSPACE}/.CONFIGURED" ]];
then
    read -r -d '' start <<-EOF

Welcome to the ForgeOps toolbox!

You'll find a recent clone of the ForgeOps git repository in the current working directory.

You should begin by bootstrapping your workspace using the boostrap-project.sh tool.

Example:
$ bootstrap-project.sh run-bootstrap 

More: 
$ bootstrap-project.sh -h 

EOF

printf "%-10s \n\n" "$start"

fi

