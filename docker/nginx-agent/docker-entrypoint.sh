#!/usr/bin/env sh
# Perform agent and environment setup then run nginx
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

# Agent properties to generate bootstrap agent.conf file properties from template
# General properties
: ${AM_AGENT_KEY:="ZGJlYzA4NTUtNjE4Mi04OQ=="}
: ${AM_AGENT_NAME:="nginx"}
: ${AM_AGENT_REALM:="/"}
: ${AM_OPENAM_URL:="http://login.example.forgeops.com:80/openam"}
: ${AM_AGENT_URL:="http://agent:80"}
: ${AM_PDP_TEMP_PATH:="/tmp/"}
: ${AM_DEBUG_FILE_PATH:="/tmp/"}
: ${AM_AUDIT_FILE_PATH:="/tmp/"}

# Secure connection properties for config file
: ${AM_SSL_CA:=" "}
: ${AM_SSL_CERT:=" "}
: ${AM_SSL_KEY:=" "}
: ${AM_SSL_PASSWORD:=" "}
: ${AM_SSL_CIPHERS:=" "}
: ${AM_SSL_OPTIONS:=" "}
: ${AM_SSL_CA:=" "}

# Proxy settings properties
: ${AM_PROXY_HOST:=" "}
: ${AM_PROXY_PORT:=" "}
: ${AM_PROXY_USER:=" "}
: ${AM_PROXY_PASSWORD:=" "}


# Override agent variables
install() {
  cd /opt/web_agents/nginx12_agent/bin
  echo "DEBUG: Agent realm is set to: $AGENT_REALM"
  # Run agentadmin to encode password with key. The awk trick is needed because output is a full text message - not the value.
  AM_AGENT_PASSWORD=$(cat /var/run/secrets/agent/.password)
  AM_AGENT_PW=`./agentadmin --p $AM_AGENT_KEY $AM_AGENT_PASSWORD |  awk 'NF>1{print $NF}'`

  # Run sed on agent.conf to replace any vars.
  cd /opt/web_agents/nginx12_agent/instances/agent_1/config/
  cp /opt/web_agents/nginx12_agent/config/agent.conf.template .

  FILE=agent.conf.template

  # Override any variables in the agent.conf file.
  cp $FILE "$FILE.bak"
  cat $FILE | \
    sed "s|AM_AGENT_PASSWORD|$AM_AGENT_PW|" | \
    sed "s|AM_AGENT_KEY|$AM_AGENT_KEY|" | \
    sed "s|AM_AGENT_NAME|$AM_AGENT_NAME|" | \
    sed "s|AM_AGENT_REALM|$AM_AGENT_REALM|" | \
    sed "s|AM_OPENAM_URL|$AM_OPENAM_URL|" | \
    sed "s|AM_AGENT_URL|$AM_AGENT_URL|" | \
    sed "s|AM_PDP_TEMP_PATH|$AM_PDP_TEMP_PATH|" | \
    sed "s|AM_DEBUG_FILE_PATH|$AM_DEBUG_FILE_PATH|" | \
    sed "s|AM_AUDIT_FILE_PATH|$AM_AUDIT_FILE_PATH|" | \
    sed "s|AM_SSL_CA|$AM_SSL_CA|" | \
    sed "s|AM_SSL_CERT|$AM_SSL_CERT|" | \
    sed "s|AM_SSL_KEY|$AM_SSL_KEY|" | \
    sed "s|AM_SSL_PASSWORD|$AM_SSL_PASSWORD|" | \
    sed "s|AM_SSL_CIPHERS|$AM_SSL_CIPHERS|" | \
    sed "s|AM_SSL_OPTIONS|$AM_SSL_OPTIONS|" | \
    sed "s|AM_SSL_CA|$AM_SSL_CA|" | \
    sed "s|AM_PROXY_HOST|$AM_PROXY_HOST|" | \
    sed "s|AM_PROXY_PORT|$AM_PROXY_PORT|" | \
    sed "s|AM_PROXY_USER|$AM_PROXY_USER|" | \
    sed "s|AM_PROXY_PASSWORD|$AM_PROXY_PASSWORD|" \
    > agent.conf
}

pause() {
  while true
  do
    sleep 6000
  done
}

case $1 in
pause)
  pause ;;
install)
  install
  exec nginx -g "daemon off;" ;;
*)
  exec $@
esac
