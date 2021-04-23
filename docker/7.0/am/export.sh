#!/usr/bin/env bash
# Script to assist in exporting AM configuration

cd /home/forgerock/openam
# tar destination defaults to /home/forgerock/updated-config.tar
# Pass `-` as the argument to output the tar stream to stdout. Use kubectl exec am-pod -- export.sh - > tar.out
dest=${1:-"/home/forgerock/updated-config.tar"}

tar -c config -f $dest
