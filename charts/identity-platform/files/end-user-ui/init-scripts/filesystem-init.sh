#!/bin/sh

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Creating usr/share"
mkdir -p /writeable/usr/share
cp -rp /usr/share/nginx /writeable/usr/share
