#!/usr/bin/env sh
# Perform agent and environment setup then run apache
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

# Set defaults. You can override these environment variables.

: ${AGENT_PW:=password}
: ${AGENT_PW_KEY:=ZGJlYzA4NTUtNjE4Mi04OQ==}
: ${AGENT_USER:=apache}
: ${AGENT_REALM:="/"}
: ${AGENT_NAMING_URL:="http://openam.example.forgeops.com:80/openam"}
: ${AGENT_URL:="http://agent:80"}


# todo: See if /secrets/apache-agent-pw exists. If it does, override the environment variable.
# If it does, use that to bootstrap the agent secret.

install() {
  cd /opt/web_agents/apache24_agent/bin
  echo "DEBUG: Agent realm is set to: $AGENT_REALM"
  # Run agentadmin to encode password with key. The awk trick is needed because output is a full text message - not the value.
  export AGENT_PW=`./agentadmin --p $AGENT_PW_KEY $AGENT_PW |  awk 'NF>1{print $NF}'`

  # For debugging:
  echo "DEBUG: encrytped password is $AGENT_PW"

  # Run sed on agent.conf to replace any vars.
  cd /opt/web_agents/apache24_agent/instances/agent_1/config/
  FILE=agent.conf

  # Override any variables in the agent.conf file.
  cp $FILE "$FILE.bak"
  cat $FILE | \
    sed "s|AGENT_PASSWORD|$AGENT_PW|"  | \
    sed "s|AGENT_PW_KEY|$AGENT_PW_KEY|"  | \
    sed "s/AGENT_USER/$AGENT_USER/" | \
    sed "s/AGENT_REALM/\\$AGENT_REALM/" | \
    sed "s+AM_SERVER+$AGENT_NAMING_URL+" | \
    sed "s+AGENT_URL+$AGENT_URL+" \
    > $FILE.new

  mv $FILE.new $FILE
}

pause() {
  while true
  do
    sleep 6000
  done
}

echo "Command: $1"


case $1 in
pause)
  pause ;;
install)
  install
  exec httpd-foreground ;;
httpd-foreground)
  exec httpd-foreground ;;
*)
  exec $@
esac
