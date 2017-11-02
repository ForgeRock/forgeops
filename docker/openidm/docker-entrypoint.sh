#!/bin/sh
# Docker entry point for OpenIDM.
set -x


if [ "$1" = 'openidm' ]; then
  
    PROJECT_HOME="${PROJECT_HOME:-/opt/openidm}"


    if [ -z "$LOGGING_CONFIG" ]; then
      if [ -n "$PROJECT_HOME" -a -r "$PROJECT_HOME"/conf/logging.properties ]; then
        LOGGING_CONFIG="-Djava.util.logging.config.file=$PROJECT_HOME/conf/logging.properties"
      elif [ -r "$OPENIDM_HOME"/conf/logging.properties ]; then
        LOGGING_CONFIG="-Djava.util.logging.config.file=$OPENIDM_HOME/conf/logging.properties"
      else
        LOGGING_CONFIG="-Dnop"
      fi
    fi

   HOSTNAME=`hostname`
   NODE_ID=${HOSTNAME}


    # Optional boot.properties file.
    # If this file is present it will override $PROJECT_HOME/conf/boot.properties
   BOOT_PROPERTIES="${BOOT_PROPERTIES:-/var/run/openidm/boot.properties}"


   # If secrets keystore is present copy files from the secrets directory to the standard location.
   if [ -r secrets/keystore.jceks ]; then
        echo "Copying Keystores"
	    cp -L secrets/*  security
   fi

    if [ -r ${BOOT_PROPERTIES} ]; then
         OPENIDM_OPTS="-Dopenidm.boot.file=${BOOT_PROPERTIES}"
    fi

   echo "Using OPENIDM_OPTS: $OPENIDM_OPTS"


   CLOPTS="-p ${PROJECT_HOME}"

   # For IDM 5.0 use this:
   #LAUNCHER="org.forgerock.commons.launcher.Main"
   # For IDM >=5.5.0 use the following:
   LAUNCHER="org.forgerock.openidm.launcher.Main"

    # Copy any patch files to the project home
    cp /opt/openidm/conf/*.patch ${PROJECT_HOME}/conf

    # Uncomment this to print experimental VM settings to the stdout.
    #java -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:MaxRAMFraction=1 -XshowSettings:vm -version


   echo "Starting OpenIDM with options: $CLOPTS"

   exec java \
        "${LOGGING_CONFIG}" \
        ${JAVA_OPTS} ${OPENIDM_OPTS} \
       -Djava.endorsed.dirs="$JAVA_ENDORSED_DIRS" \
       -classpath /opt/openidm/bin/*:/opt/openidm/framework/* \
       -Dopenidm.system.server.root=/opt/openidm \
       -Djava.endorsed.dirs= \
       -Djava.awt.headless=true \
       -Dopenidm.node.id="${NODE_ID}" \
       ${LAUNCHER}  -c /opt/openidm/bin/launcher.json ${CLOPTS}
fi

# Else - exec the arguments pass to the entry point.
exec  "$@"
