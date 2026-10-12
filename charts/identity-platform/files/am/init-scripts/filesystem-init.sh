#!/bin/sh

if [ -d /fbc/config ]; then
  echo "Existing openam configuration found. Skipping copy."
elif [ -d /custom/config ]; then
  echo "Found config in custom volume."
  cd /home/forgerock/openam
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
  cd /home/forgerock/openam
  cp -r .homeVersion * /fbc
  # Keep a copy of the default boot.json to use in the main container in case of a container restart
  cp /fbc/config/boot.json /fbc/default-boot.json
fi

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /home/forgerock"
mkdir -p /writeable/home
cp -av /home/forgerock/ /writeable/home/forgerock
cp -av /usr/local/tomcat /writeable/tomcat
