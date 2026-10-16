#!/bin/sh
# The AM filesystem init, shared by the Debian and Alpine image lines.
# Layout differences are resolved at runtime:
#   - home: the alpine pingbase images bake FORGEROCK_HOME=/home/ping; the
#     Debian images set nothing -> /home/forgerock. The writeable-volume
#     destination follows the SAME basename the chart mounts at
#     (am-deployment.yaml mounts the writeable volume at
#     subPath "home/<basename of platform.amHome>").
#   - tomcat: the Debian image has a real /usr/local/tomcat directory; the
#     pingbase-tomcat alpine image installs Tomcat under
#     /opt/apache-tomcat-<ver> with a /opt/tomcat symlink.
if [ -z "${FORGEROCK_HOME:-}" ]; then
  FORGEROCK_HOME=/home/forgerock
fi

if [ -d /fbc/config ]; then
  echo "Existing openam configuration found. Skipping copy."
elif [ -d /custom/config ]; then
  echo "Found config in custom volume."
  cd "${FORGEROCK_HOME}/openam"
  cp -rv .homeVersion * /fbc
  # Deployer-provided configuration wins: the custom content is a WHOLESALE
  # replacement of the config tree (unlike idm there is no profile-overlay
  # marker to drop — the AM image applies its CONFIG_PROFILE at build time).
  cp -av /custom/config /fbc
  if [ ! -f /fbc/config/boot.json ]; then
    echo "WARNING: the custom config does not include config/boot.json, so" >&2
    echo "WARNING: this does not look like a complete openam configuration." >&2
    echo "WARNING: AM may fail to boot or restart cleanly." >&2
  fi
  cp /fbc/config/boot.json /fbc/default-boot.json
else
  echo "Copying docker image configuration files to the shared volume"
  cd "${FORGEROCK_HOME}/openam"
  cp -r .homeVersion * /fbc
  # Keep a copy of the default boot.json to use in the main container in case of a container restart
  cp /fbc/config/boot.json /fbc/default-boot.json
fi

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying ${FORGEROCK_HOME}"
mkdir -p "/writeable/home/$(basename "${FORGEROCK_HOME}")"
# Copy with `cp -rv` (NOT -a): some files are root-owned in the image, and
# busybox cp -a exits 1 when it cannot preserve ownership (GNU cp only
# warns). The init runs as the product uid, so plain -r ownership (files
# owned by the runner) is exactly right for the writeable volume.
cp -rv "${FORGEROCK_HOME}/." "/writeable/home/$(basename "${FORGEROCK_HOME}")/"
# Locate the Tomcat installation: /usr/local/tomcat (Debian, a real
# directory) or /opt/tomcat (alpine pingbase, a SYMLINK to
# /opt/apache-tomcat-<ver>). Either way copy the DIRECTORY CONTENTS, not
# the link: copying a symlink would place a dangling link on the writeable
# volume and the kubelet then fails the main container with "failed to
# create subPath directory" for the "tomcat" subPath.
if [ -d /usr/local/tomcat ]; then
  TOMCAT_SRC=/usr/local/tomcat
elif [ -d /opt/tomcat/ ]; then
  TOMCAT_SRC=/opt/tomcat
else
  echo "ERROR: no Tomcat installation found (expected /usr/local/tomcat or /opt/tomcat)" >&2
  exit 1
fi
mkdir -p /writeable/tomcat
cp -rv "${TOMCAT_SRC}/." /writeable/tomcat/
