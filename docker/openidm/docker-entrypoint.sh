#!/bin/sh
# Docker entry point for OpenIDM.

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

   REPO_HOST="${POSTGRESQL_SERVICE_HOST:-postgresql}"
   REPO_PORT="${POSTGRESQL_SERVICE_PORT:-5432}"
   REPO_USER="openidm"
   REPO_PASSWORD="openidm"

   KEYSTORE_PASSWORD=changeit

   # Check for secret volumes and use those if present.
   if [ -r secrets/keystore.pin ]; then
      KEYSTORE_PASSWORD=`cat secrets/keystore.pin`
   fi

   O1="-Dopenidm.keystore.password=${KEYSTORE_PASSWORD} -Dopenidm.truststore.password=${KEYSTORE_PASSWORD}"

   # If secrets keystore is present copy files from the secrets directory to the standard location.
   if [ -r secrets/keystore.jceks ]; then
	cp secrets/*  security
	chown -R openidm:openidm security 
   fi

   O2="-Dopenidm.repo.host=$REPO_HOST -Dopenidm.repo.port=$REPO_PORT -Dopenidm.repo.user=${REPO_USER} -Dopenidm.repo.password=${REPO_PASSWORD}"
   O3="-Dopenidm.node.id=$NODE_ID"
   # This is the default
   O4="-Dopenidm.fileinstall.enabled=true"

   OPENIDM_OPTS="$O1 $O2 $O3 $O4"

   echo "Using OPENIDM_OPTS:   $OPENIDM_OPTS"

   CLOPTS="-p ${PROJECT_HOME}"

   #LAUNCHER="org.forgerock.commons.launcher.Main"
   # For OpenIDM-5.5.0 use the following:
   LAUNCHER="org.forgerock.openidm.launcher.Main"


    echo "Starting OpenIDM"

   # The openidm user can not mount the hostPath volume in Minikube due to VirtualBox permissions,
   # so we run as root for now.
   #exec su-exec openidm java
   exec java \
        "${LOGGING_CONFIG}" \
        ${JAVA_OPTS} ${OPENIDM_OPTS} \
       -Djava.endorsed.dirs="$JAVA_ENDORSED_DIRS" \
       -classpath /opt/openidm/bin/*:/opt/openidm/framework/* \
       -Dopenidm.system.server.root=/opt/openidm \
       -Djava.endorsed.dirs= \
       -Djava.awt.headless=true \
       ${LAUNCHER}  -c /opt/openidm/bin/launcher.json ${CLOPTS}
fi

exec su-exec openidm "$@"
