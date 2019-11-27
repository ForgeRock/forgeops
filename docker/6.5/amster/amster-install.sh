#!/usr/bin/env bash
#!/usr/bin/env bash
# Full amster install.


DIR=`pwd`

# Path to script location - this is *not* the path to the amster/*.json config files - it is the path
# to  *.amster scripts.
AMSTER_SCRIPTS=${AMSTER_SCRIPTS:-"${DIR}/scripts"}

# Default directory for optional post install scripts. Anything in this directory will be executed after
# all amster scripts have run.
POST_INSTALL_SCRIPTS=${POST_INSTALL_SCRIPTS:-"${AMSTER_SCRIPTS}"}


# Use 'openam' as the internal cluster dns name.
export SERVER_URL=${OPENAM_INSTANCE:-http://am:80}
export URI=${SERVER_URI:-/am}

export INSTANCE="${SERVER_URL}${URI}"

# Alive check
ALIVE="${INSTANCE}/isAlive.jsp"
# Config page. This comes up if AM is not configured.
CONFIG_URL="${INSTANCE}/config/options.htm"

# Wait for AM to come up before configuring it.
# Curl times out after 2 minutes regardless of the --connect-timeout setting.
# todo: Find a faster way to test for AM readiness
wait_for_openam()
{
    # If we get lucky, AM will be up before the first curl command is issued.
    sleep 20
   response="000"

	while true
	do
		response=$(curl --write-out %{http_code} --silent --connect-timeout 30 --output /dev/null ${CONFIG_URL} )

      echo "Got Response code $response"
      if [ ${response} = "302" ]; then
         echo "Checking to see if AM is already configured. Will not reconfigure"

         curl ${CONFIG_URL} | grep -q "Configuration"
         if [ $? -eq 0  ]; then
            break
         fi
         echo "It looks like AM is already configured . Exiting"
         exit 0
      fi
      if [ ${response} = "200" ];
      then
         echo "AM web app is up and ready to be configured"
         break
      fi

      echo "response code ${response}. Will continue to wait"
      sleep 5
   done

	# Sleep additional time in case DS is not quite up yet.
	echo "About to begin configuration"
}

echo "Waiting for AM server at ${CONFIG_URL} "

wait_for_openam

# CLOUD-1639
# On occaasion, AM can be up before the config store is up, causing the amster install
# to fail. The sleep is a low tech solution...
sleep 30

# Execute Amster if the configuration is found.
if [ -d  ${AMSTER_SCRIPTS} ]; then
    if [ ! -r /var/run/secrets/amster/id_rsa ]; then
        echo "ERROR: Can not find the Amster private key"
        exit 1
    fi

    echo "Executing Amster to configure AM"
    # Need to be in the amster directory, otherwise Amster can't find its libraries.
    # todo: just execute the install - no import
    cd ${DIR}
    for file in ${AMSTER_SCRIPTS}/*.amster
    do
        echo "Executing Amster script $file"
        sh ./amster ${file}
    done
fi

# Execute any shell scripts ending with *sh
if [ -d ${POST_INSTALL_SCRIPTS} ]; then
    for script in ${POST_INSTALL_SCRIPTS}/*.sh
    do
        if [ -x ${script} ]; then
            echo "Executing $script"
            ${script}
        fi
    done
fi


echo "Configuration script finished"