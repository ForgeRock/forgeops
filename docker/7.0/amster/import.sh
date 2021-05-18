#!/usr/bin/env bash
# Import dynamic config.

# Alive check
ALIVE="${AMSTER_AM_URL}/json/health/ready"

wait_for_openam()
{
   echo "Waiting for AM server at ${ALIVE}..."
   response="000"

	while true
	do
	  echo "Trying ${ALIVE}"
		response=$(curl --write-out %{http_code} --silent --connect-timeout 30 --output /dev/null ${ALIVE} )

      echo "Got Response code ${response}"
      if [ "${response}" = "200" ];
      then
         echo "AM web app is up"
         break
      fi

      echo "Will continue to wait..."
      sleep 5
   done
}


# Function that waits for files to be uploaded to /opt/amster/config/upload
# This would usually be done via kubectl cp
wait_config_file_upload()
{
   TIMEOUT=60
   mkdir -p /opt/amster/config/upload
   echo "Waiting for files to be uploaded"
   inotifywait /opt/amster/config/upload  -e create --timeout $TIMEOUT || {
      echo "No uploaded files were found within $TIMEOUT seconds. Exiting"
      exit 1
   }
   echo "Files uploaded - proceeding with amster import"
}


# Import config - script is passed in $1
import() {

   echo "Executing script $1"

   # Execute Amster if the configuration is found.
   if [  ${1} ]; then
      if [ ! -r /var/run/secrets/amster/id_rsa ]; then
         echo "ERROR: Can not find the Amster private key"
         exit 1
      fi

      echo "Executing Amster to import dynamic config"
      # Need to be in the amster directory, otherwise Amster can't find its libraries.

      # Use the internal hostname for AM. The external name might not have a proper SSL certificate
      $JAVA_HOME/bin/java -jar ./amster-*.jar  "${1}" -q -D AM_HOST="${INSTANCE}"  > /tmp/out.log 2>&1

      echo "Amster output *********"
      cat /tmp/out.log

      # This is a workaround to test if the import failed, and return a non zero exit code if it did
      # See https://bugster.forgerock.org/jira/browse/OPENAM-11431
      if grep -q 'ERRORS\|Configuration\ failed\|Could\ not\ connect\|No\ connection\|Unexpected\ response' </tmp/out.log; then
            echo "Amster import errors"
            exit 1
      fi
   fi

   echo  "import done"
}

cat >/tmp/import.amster <<EOF
connect $AMSTER_AM_URL -k /var/run/secrets/amster/id_rsa
import-config --path /opt/amster/config  --clean false
:exit
EOF

wait_for_openam

# If there is no arg - just import any files found in config/
if [[ -z "$1" ]]; then
   import "/tmp/import.amster"
else
   # Else- wait for upload
   wait_config_file_upload
   sleep 5
   import "/tmp/import.amster"
fi
