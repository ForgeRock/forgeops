#!/usr/bin/env bash
# Script to assist in exporting PingAM configuration

cd /home/forgerock/openam

cfgServiceDir="config/services/realm/root/configurationversionservice/1.0/globalconfig"

# copy the configurationservice over so it can be exported and used by the am-config-upgrader
mkdir -p ${cfgServiceDir}
cp "/home/forgerock/cdk/${cfgServiceDir}/default.json" ${cfgServiceDir}

# tar destination defaults to /home/forgerock/updated-config.tar
# Pass `-` as the argument to output the tar stream to stdout. Use kubectl exec am-pod -- export.sh - > tar.out
dest=${1:-"/home/forgerock/updated-config.tar"}

# only create tar file if there is any changed configuration
if [ "$(ls -A config/services)" ]; then 
    tar --exclude='boot.json' --exclude='auth' --exclude='README.txt' -cf $dest config
fi