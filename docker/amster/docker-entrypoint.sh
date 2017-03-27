#!/usr/bin/env sh
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Run the configurator and any other config
# Assumes that /var/tmp/openam.properties has been placed in the container filesystem
# Container puts everything in


# If this is not the configure command, then execute the command
# This can be used to run the container in an interactive mode (say with /bin/sh) to issue
# Amster commands
if [ ! "$1" = 'configure' ]; then
    exec "$@"
fi

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
		echo "Waiting for OpenAM server at ${CONFIG_URL} "

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


wait_for_openam


AMSTER_CONFIG=${AMSTER_CONFIG:-/amster}


# Execute Amster if the configuration is found.
if [ -d  ${AMSTER_CONFIG} ]; then
    if [ ! -r /var/secrets/amster/id_rsa ]; then
        echo "ERROR: Can not find the Amster private key"
        exit 1
    fi

    echo "Executing Amster to configure OpenAM"
    # Need to be in the amster directory, otherwise Amster can't find its libraries.
    cd /var/tmp/amster
    for file in ${AMSTER_CONFIG}/*.amster
    do
        echo "Executing Amster script $file"
        sh ./amster ${file}
    done

fi


# We watch for this message in scripting - so leave text exactly as is.
echo ""
echo "Configuration script finished"

# This file can be checked by the readiness probe to see if the install container is "ready".
touch /var/tmp/CONFIGURED

# Sleep forever in case the user wants to examine the container logs.
while true
do
    sleep 5000
done
