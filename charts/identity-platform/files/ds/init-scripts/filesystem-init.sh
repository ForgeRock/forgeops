#!/bin/sh

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /home/forgerock"
mkdir -p /writeable/home
cp -av /home/forgerock/ /writeable/home/forgerock/
echo "Copying /opt/opendj"
mkdir -p /writeable/opt
cp -av /opt/opendj/ /writeable/opt/opendj/
