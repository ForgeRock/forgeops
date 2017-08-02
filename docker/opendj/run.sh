#!/usr/bin/env sh
# Run the OpenDJ server
# We consolidate all of the writable DJ directories to /opt/opendj/data
# This allows us to to mount a data volume on that root which  gives us
# persistence across restarts of OpenDJ.
# For Docker - mount a data volume on /opt/opendj/data
# For Kubernetes mount a PV
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

cd /opt/opendj

# If the pod was terminated abnormally the lock file may not have gotten cleaned up.
rm -f /opt/opendj/locks/server.lock

# Uncomment this to print experimental VM settings to the stdout.
java -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:MaxRAMFraction=1 -XshowSettings:vm -version


# Instance dir does not exist? Then we need to run setup
if [ ! -d ./data/config ] ; then
  echo "Instance data Directory is empty. Creating new DJ instance"
  BOOTSTRAP=${BOOTSTRAP:-/opt/opendj/bootstrap/setup.sh}
  # Set a default base DN. Setup scripts can choose to override this.
  # If a password file is mounted, grab the password from that, otherwise default
  if [ ! -r "$DIR_MANAGER_PW_FILE" ]; then
    echo "Warning; Can't find path to $DIR_MANAGER_PW_FILE. I will create a default DJ admin password"
    mkdir -p "$SECRET_PATH"
    echo -n "password" > "$DIR_MANAGER_PW_FILE"
  fi
  PW=`cat $DIR_MANAGER_PW_FILE`
  export PASSWORD=${PW:-password}

   echo "Running $BOOTSTRAP"
   sh "${BOOTSTRAP}"

   # Check if DJ_MASTER_SERVER var is set. If it is - replicate to that server.
   if [ ! -z ${DJ_MASTER_SERVER+x} ];  then
      /opt/opendj/replicate.sh $DJ_MASTER_SERVER
   fi
fi

if [ -d "${SECRET_PATH}" ]; then
  echo "Secret path is present. Will copy any keystores and truststore"
  # We send errors to /dev/null in case no data exists.
  cp -f ${SECRET_PATH}/key*   ${SECRET_PATH}/trust* ./data/config 2>/dev/null
fi

# todo: Check /opt/opendj/data/config/buildinfo
# Run upgrade if the server is older


if (bin/status -n | grep Started) ; then
   # A restart is needed to ensure we pick up any JVM env var args
   echo "Restarting OpenDJ after installation."
   bin/stop-ds
fi

echo "Starting OpenDJ"

# Remove any boostrapping sententil set by setup.sh. 
rm -f /opt/opendj/BOOTSTRAPPING


INSTANCE_ROOT=/opt/opendj/data

# instance.loc points DJ at the data/ volume
echo $INSTANCE_ROOT >/opt/opendj/instance.loc

exec ./bin/start-ds --nodetach