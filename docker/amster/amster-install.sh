#!/usr/bin/env sh
# Full amster install


DIR=`pwd`

CONFIG_ROOT=${CONFIG_ROOT:-"${DIR}/git"}
#CONFIG_LOCATION=${CONFIG_LOCATION:-"forgeops-init/amster"}
# Path to script location - this is *not* the path to the amster/*.json config files - it is the path
# to  *.amster scripts.
AMSTER_SCRIPTS=${AMSTER_SCRIPTS:-"${DIR}/scripts"}


# Else - configure

# When OpenAM is in the Kubernetes cluster, use 'openam' for defaults.
export SERVER_URL=${OPENAM_INSTANCE:-http://openam:80}
export URI=${SERVER_URI:-/openam}

export INSTANCE="${SERVER_URL}${URI}"

# Alive check
ALIVE="${INSTANCE}/isAlive.jsp"
# Config page. This comes up if OpenAM is not configured.
CONFIG_URL="${INSTANCE}/config/options.htm"

# Wait for OpenAM to come up before configuring it.
# Curl times out after 2 minutes regardless of the --connect-timeout setting.
# todo: Find a faster way to test for OpenAM readiness
wait_for_openam()
{
    # If we get lucky, OpenAM will be up before the first curl command is issued.
    sleep 40
   response="000"

	while true
	do
		response=$(curl --write-out %{http_code} --silent --connect-timeout 30 --output /dev/null ${CONFIG_URL} )

      echo "Got Response code $response"
      if [ ${response} = "302" ]; then
         echo "Checking to see if OpenAM is already configured. Will not reconfigure"

         curl ${CONFIG_URL} | grep -q "Configuration"
         if [ $? -eq 0  ]; then
            break
         fi
         echo "It looks like OpenAM is configured already. Exiting"

         exit 0
      fi
      if [ ${response} = "200" ];
      then
         echo "OpenAM web app is up and ready to be configured"
         break
      fi

      echo "response code ${response}. Will continue to wait"
      sleep 5
   done

	# Sleep additional time in case OpenDJ is not quite up yet.
	echo "About to begin configuration"
}

echo "Waiting for OpenAM server at ${CONFIG_URL} "

wait_for_openam


# Execute Amster if the configuration is found.
if [ -d  ${AMSTER_SCRIPTS} ]; then
    if [ ! -r /var/secrets/amster/id_rsa ]; then
        echo "ERROR: Can not find the Amster private key"
        exit 1
    fi

    echo "Executing Amster to configure OpenAM"
    # Need to be in the amster directory, otherwise Amster can't find its libraries.
    cd ${DIR}
    for file in ${AMSTER_SCRIPTS}/*.amster
    do
        echo "Executing Amster script $file"
        sh ./amster ${file}
    done

fi

# Todo: we might want this script to dynamically create the boot.json configmap, so new AM instances boot.
# See https://bugster.forgerock.org/jira/browse/AME-13657 

echo "Configuration script finished"