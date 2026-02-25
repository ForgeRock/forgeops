#!/bin/sh

if [ -d /fbc/config ]; then
  echo "Existing openam configuration found. Skipping copy."
elif [ -d /custom/config ]; then
  echo "Found config in custom volume."
  cd /home/forgerock/openam
  cp -rv .homeVersion * /fbc
  cp -av /custom/config /fbc
  cp /fbc/config/boot.json /fbc/default-boot.json
else
  echo "Copying docker image configuration files to the shared volume"
  cd /home/forgerock/openam
  cp -r .homeVersion * /fbc
  # Keep a copy of the default boot.json to use in the main container in case of a container restart
  cp /fbc/config/boot.json /fbc/default-boot.json
fi
