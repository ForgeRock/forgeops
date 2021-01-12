#!/usr/bin/env bash
# Import dynamic config.

PS4='+ $(date "+%H:%M:%S")\011 '

DIR=`pwd`

IMPORT_SCRIPT=${IMPORT_SCRIPT:-"${DIR}/amster-scripts/import.amster"}

# Use 'openam' as the internal cluster dns name.
export SERVER_URL=${OPENAM_INSTANCE:-http://am:80}
export URI=${SERVER_URI:-/am}

export INSTANCE="${SERVER_URL}${URI}"

# Alive check
ALIVE="${INSTANCE}/json/health/ready"

wait_for_openam()
{
   # If we get lucky, AM will be up before the first curl command is issued.
   sleep 20
   response="000"

	while true
	do
	  echo "Trying ${ALIVE}"
		response=$(curl --write-out %{http_code} --silent --connect-timeout 30 --output /dev/null ${ALIVE} )

      echo "Got Response code ${response}"
      if [ ${response} = "200" ];
      then
         echo "AM web app is up"
         break
      fi

      echo "Will continue to wait..."
      sleep 5
   done
}


echo "Waiting for AM server at ${ALIVE}..."

wait_for_openam

echo "About to begin dynamic data import"

# Execute Amster if the configuration is found.
if [  ${IMPORT_SCRIPT} ]; then
    if [ ! -r /var/run/secrets/amster/id_rsa ]; then
        echo "ERROR: Can not find the Amster private key"
        exit 1
    fi

    echo "Executing Amster to import dynamic config"
    # Need to be in the amster directory, otherwise Amster can't find its libraries.

    cd ${DIR}

   # Use the internal hostname for AM. The external name might not have a proper SSL certificate
    $JAVA_HOME/bin/java -jar ./amster-*.jar  ${IMPORT_SCRIPT} -q -D AM_HOST="${INSTANCE}"  > /tmp/out.log 2>&1

   echo "Amster output *********"
   cat /tmp/out.log

   # This is a workaround to test if the import failed, and return a non zero exit code if it did
   # See https://bugster.forgerock.org/jira/browse/OPENAM-11431
   if grep -q 'ERRORS\|Configuration\ failed\|Could\ not\ connect\|No\ connection\|Unexpected\ response' </tmp/out.log; then
         echo "Amster import errors"
         exit 1
   fi
fi

echo  "done"
