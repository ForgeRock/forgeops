#!/bin/sh

if [ "$(ls -A /config/)" ] ; then
  echo "Found config in custom volume."
  cp -av /custom/* /fbc/config
fi
