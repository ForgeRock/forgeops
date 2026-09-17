#!/bin/sh
# Alpine pingam variant of files/am/init-scripts/filesystem-init.sh: the
# pingbase images use /home/ping (PING_HOME) instead of /home/forgerock, and
# pingbase-tomcat installs Tomcat at /opt/tomcat instead of /usr/local/tomcat.

if [ -d /fbc/config ]; then
  echo "Existing openam configuration found. Skipping copy."
elif [ -d /custom/config ]; then
  echo "Found config in custom volume."
  cd /home/ping/openam
  cp -rv .homeVersion * /fbc
  cp -av /custom/config /fbc
  cp /fbc/config/boot.json /fbc/default-boot.json
else
  echo "Copying docker image configuration files to the shared volume"
  cd /home/ping/openam
  cp -r .homeVersion * /fbc
  # Keep a copy of the default boot.json to use in the main container in case of a container restart
  cp /fbc/config/boot.json /fbc/default-boot.json
fi

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /home/ping"
mkdir -p /writeable/home
# Copy with `cp -rv` (NOT -a): some files are root-owned in the image, and
# busybox cp -a exits 1 when it cannot preserve ownership (GNU cp only
# warns). The init runs as the am uid (9031), so plain -r ownership (files
# owned by the runner) is exactly right for the writeable volume.
cp -rv /home/ping/. /writeable/home/ping
# /opt/tomcat is a SYMLINK to /opt/apache-tomcat-<ver> in the pingbase
# alpine images (the Debian image's /usr/local/tomcat is a real directory),
# so copy its contents, not the link: `cp -a /opt/tomcat` would place a
# dangling symlink on the writeable volume and the kubelet then fails the
# main container with "failed to create subPath directory" for the
# "tomcat" subPath (seen as missing through the link, mkdir hits EEXIST).
mkdir -p /writeable/tomcat
cp -rv /opt/tomcat/. /writeable/tomcat/
