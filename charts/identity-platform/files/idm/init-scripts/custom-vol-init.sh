#!/bin/sh

if [ -d /custom/config ]; then
    echo "Existing openidm configuration found in /custom. Skipping copy."
elif [ -n "$(ls -A /config)" ]; then
    echo "Copying configuration files to the custom volume."
    mkdir -p /custom/config
    cp -rv /config/* /custom/config/
    ls -F /custom
else
    echo "No custom FBC found. Continuing with defaults."
fi

if [ -d /connectors ] && [ -n "$(ls -A /connectors)" ] ; then
    echo "Copying custom connectors to the custom volume."
    mkdir -p /custom/connectors
    cp -rv /connectors/* /custom/connectors
else
    echo "No custom connectors found. Continuing."
fi
