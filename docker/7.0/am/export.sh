#!/usr/bin/env bash
# Script to assist in exporting AM configuration

cd /home/forgerock/openam

cfgServiceDir="config/services/realm/root/configurationversionservice/1.0/globalconfig"

# copy the configurationservice over so it can be exported and used by the am-config-upgrader
mkdir -p ${cfgServiceDir}
cp "/home/forgerock/cdk/${cfgServiceDir}/default.json" ${cfgServiceDir}

# tar destination defaults to /home/forgerock/updated-config.tar
# Pass `-` as the argument to output the tar stream to stdout. Use kubectl exec am-pod -- export.sh - > tar.out
dest=${1:-"/home/forgerock/updated-config.tar"}

tar --exclude boot.json -cf $dest config
