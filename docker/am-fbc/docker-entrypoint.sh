#!/bin/sh

# Add file based config option
# -Dorg.forgerock.donotupgrade - optional - may cause issues
export CATALINA_OPTS="${CATALINA_OPTS}  -Dcom.sun.identity.sm.sms_object_filebased_enabled=true"
echo "CATALINAOPTS= $CATALINA_OPTS"

exec /usr/local/tomcat/bin/catalina.sh run
