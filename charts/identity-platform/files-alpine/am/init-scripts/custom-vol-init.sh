#!/bin/sh

if [ -d /custom/config ]; then
  echo "Existing openam configuration found in /custom. Skipping copy."
elif [ -d /config/config ]; then
  echo "Copying configuration files to the custom volume."
  cp -rv /config/config /custom
else
  echo "No custom FBC found. Continuing with defaults."
fi
