#!/bin/sh

if [ "$(ls -A /custom/conf)" ]; then
  echo "Existing ig configuration found in /custom. Skipping copy."
elif [ "$(ls -A /config/)" ]; then
  echo "Copying configuration files to the custom volume."
  cp -rv /config/* /custom
else
  echo "No custom FBC found. Continuing with defaults."
fi
