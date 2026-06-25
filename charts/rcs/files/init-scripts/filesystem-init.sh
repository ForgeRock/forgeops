#!/bin/sh

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /opt/openicf."
rm -rf /writeable/openicf
cp -av /opt/openicf /writeable/openicf

if [ -n "$(ls /custom_lib 2>/dev/null)" ] ; then
  echo "Found /custom_lib dir. Copying."
  ls -aF /custom_lib
  cp -av /custom_lib/* /writeable/openicf/lib
fi
