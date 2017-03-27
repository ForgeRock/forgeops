#!/usr/bin/env sh
# Run the OpenDJ server
# The idea is to consolidate all of the writable DJ directories to
# a single instance directory root, and update DJ's instance.loc file to point to that root
# This allows us to to mount a data volume on that root which  gives us
# persistence across restarts of OpenDJ.
# For Docker - mount a data volume on /opt/opendj/data
# For Kubernetes mount a PV
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file


cd /opt/opendj


# Instance dir does not exist? Then we need to run setup
if [ ! -d ./data/config ] ; then
  echo "Instance data Directory is empty. Creating new DJ instance"

  BOOTSTRAP=${BOOTSTRAP:-/opt/opendj/bootstrap/setup.sh}

  # Set a default base DN. Setup scripts can choose to override this.
  export BASE_DN=${BASE_DN:-"dc=example,dc=com"}
  # If a password file is mounted, grab the password from that, otherwise default
  PW=`cat $DIR_MANAGER_PW_FILE`
  export PASSWORD=${PW:-password}

   echo "Running $BOOTSTRAP"
   sh "${BOOTSTRAP}"

   # Check if DJ_MASTER_SERVER var is set. If it is - replicate to that server
   if [ ! -z ${DJ_MASTER_SERVER+x} ];  then
      /opt/opendj/bootstrap/replicate.sh $DJ_MASTER_SERVER
   fi
fi

# Check if keystores are mounted as a volume, and if so
# Copy any keystores over
SECRET_VOLUME=${SECRET_VOLUME:-/var/secrets/opendj}

if [ -d "${SECRET_VOLUME}" ]; then
  echo "Secret volume is present. Will copy any keystores and truststore"
  # We send errors to /dev/null in case no data exists.
  cp -f ${SECRET_VOLUME}/key*   ${SECRET_VOLUME}/trust* ./data/config 2>/dev/null
fi

# todo: Check /opt/opendj/data/config/buildinfo
# Run upgrade if the server is older


if (bin/status -n | grep Started) ; then
   # A restart is needed to ensure we pick up any JVM env var args
   echo "Restarting OpenDJ after installation."
   bin/stop-ds
fi


echo "Starting OpenDJ"

#

exec ./bin/start-ds --nodetach