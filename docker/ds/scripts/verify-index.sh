#!/usr/bin/env bash
# Verify the index. This can used to verify data integrity
# after a restore from backup. Note this is *very* slow.
# export-ldif is recommended instead. See the verify.sh script.


# Get a list of backends
cd /opt/opendj

# For each backend, grab the basedn.

configfile=config/config.ldif

for backend in `bin/dsconfig --offline list-backends -s -n `
do

    if [ "$backend" = "adminRoot" ]  || [ "$backend" = "rootUser" ] || [ "$backend" = "monitorUser" ]
    then
        continue
    fi

    basedn=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile \
        | grep "ds-cfg-base-dn: " | sed "s/ds-cfg-base-dn: //" | sed "s/ /-/g"`

    echo "Verifying index for basedn of $basedn."
    bin/verify-index --baseDn "$basedn"

    if [ $? -ne 0 ]
    then
        echo "verify index failed for $basedn."
        scripts/slack.sh "Verify index failed for $basedn" "ERROR"
        exit 1
    fi
    scripts/slack.sh "Verify index passed for $basedn" "INFO"

done
