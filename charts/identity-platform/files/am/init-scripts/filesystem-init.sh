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

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /home/forgerock"
mkdir -p /writeable/home
cp -av /home/forgerock/ /writeable/home/forgerock
cp -av /usr/local/tomcat /writeable/tomcat
