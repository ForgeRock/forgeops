#!/bin/sh

if [ -d /fbc/conf ]; then
  echo "Existing openidm configuration found. Skipping copy."
elif [ -d /custom/config ]; then
  echo "Found config in custom volume."
  cd /opt/openidm
  cp -rv ui conf script /fbc
  cp -av /custom/config/* /fbc/
else
  echo "Copying docker image configuration files to the shared volume"
  cd /opt/openidm
  cp -rv ui conf script /fbc
fi

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /opt/openidm"
mkdir -p /writeable/opt
cp -av /opt/openidm/ /writeable/opt/openidm
