#!/usr/bin/env bash
# Verify the data by performing an export-ldif. This is used to test
# the data after a restore from a binary backup.

cd /opt/opendj

for backend in `bin/dsconfig --offline list-backends -s -n `
do

    if [ "$backend" = "adminRoot" ]  || [ "$backend" = "rootUser" ] || [ "$backend" = "monitorUser" ]
    then
        continue
    fi

    echo "Verifying backend $backend"
    bin/export-ldif --offline --backendId "$backend" -l /dev/null

    if [ $? -ne 0 ]
    then
        echo "verify data failed for $basedn."
        scripts/notify.sh "Verify of directory data failed for $backend" "ERROR"
        exit 1
    fi
    scripts/notify.sh "Verify of directory data OK for $backend" "INFO"
done
