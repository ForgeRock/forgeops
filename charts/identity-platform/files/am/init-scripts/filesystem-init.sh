#!/bin/sh
# The AM filesystem init, shared by the Debian and Alpine image lines.
# Layout is driven by the CHART, not probed: the filesystem-init container
# runs with FORGEROCK_HOME (the image's home directory — the writeable-home
# destination, the same value the writeable subPath basename uses), AM_HOME
# (the image's openam directory) and AM_CATALINA_HOME (the image's Tomcat
# directory) set from platform.amHome/platform.amCatalina — the same helpers
# that place the writeable-volume subPaths in the main container — so the
# chart and this script cannot disagree about the layout even when the
# pinned image and platform.imageMode diverge. The fallbacks below keep
# standalone (non-chart) runs working.
if [ -z "${FORGEROCK_HOME:-}" ]; then
  if [ -n "${AM_HOME:-}" ]; then
    FORGEROCK_HOME=${AM_HOME%/openam}
  else
    FORGEROCK_HOME=/home/forgerock
    AM_HOME="${FORGEROCK_HOME}/openam"
  fi
fi
if [ -z "${AM_HOME:-}" ]; then
  AM_HOME="${FORGEROCK_HOME}/openam"
fi
if [ -z "${AM_CATALINA_HOME:-}" ]; then
  # Standalone fallback: the Debian image has a real /usr/local/tomcat; the
  # pingbase-tomcat alpine image installs Tomcat under
  # /opt/apache-tomcat-<ver> with a /opt/tomcat symlink.
  if [ -d /usr/local/tomcat ]; then
    AM_CATALINA_HOME=/usr/local/tomcat
  elif [ -d /opt/tomcat/ ]; then
    AM_CATALINA_HOME=/opt/tomcat
  else
    echo "ERROR: no Tomcat installation found (set AM_CATALINA_HOME; expected /usr/local/tomcat or /opt/tomcat)" >&2
    exit 1
  fi
fi

if [ -d /fbc/config ]; then
  echo "Existing openam configuration found. Skipping copy."
elif [ -d /custom/config ]; then
  echo "Found config in custom volume."
  # Guard the cd: a failed cd would leave the glob '*' at the container
  # root and copy /proc into /fbc.
  cd "${AM_HOME}" || exit 1
  cp -rv .homeVersion * /fbc
  # Deployer-provided configuration wins: the custom content is a WHOLESALE
  # replacement of the config tree (unlike idm there is no profile-overlay
  # marker to drop — the AM image applies its CONFIG_PROFILE at build time).
  cp -av /custom/config /fbc
  if [ ! -f /fbc/config/boot.json ]; then
    echo "WARNING: the custom config does not include config/boot.json, so" >&2
    echo "WARNING: this does not look like a complete openam configuration." >&2
    echo "WARNING: AM may fail to boot or restart cleanly." >&2
  fi
  cp /fbc/config/boot.json /fbc/default-boot.json
else
  echo "Copying docker image configuration files to the shared volume"
  cd "${AM_HOME}" || exit 1
  cp -r .homeVersion * /fbc
  # Keep a copy of the default boot.json to use in the main container in case of a container restart
  cp /fbc/config/boot.json /fbc/default-boot.json
fi

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying ${FORGEROCK_HOME}"
mkdir -p "/writeable/home/$(basename "${FORGEROCK_HOME}")"
# `cp -dRv` (NOT -a): -a implies -p (preserve mode/ownership), which busybox
# cp cannot honor as the init's non-root uid and warns per file ("can't
# preserve ownership") — noise on every boot. -d/-P (preserve symlinks) is
# already busybox's default with -R, but stating it keeps GNU cp — where the
# default depends on build config — behaving identically. -R recurses; both
# busybox cp and GNU cp support the -dR pair. (Measured on busybox 1.38:
# `cp -a` warns per unownable file but EXITS 0; dropping -p trades that
# warning noise for copied files getting src_mode & ~umask — acceptable for
# the writeable mirror, which the main container re-owns via fsGroup.)
cp -dRv "${FORGEROCK_HOME}/." "/writeable/home/$(basename "${FORGEROCK_HOME}")/"
# Copy the Tomcat CONTENTS, not a symlink: AM_CATALINA_HOME may be a
# symlink (/opt/tomcat -> /opt/apache-tomcat-<ver> on pingbase-tomcat), and
# copying a symlink would place a dangling link on the writeable volume;
# the kubelet then fails the main container with "failed to create subPath
# directory" for the "tomcat" subPath.
mkdir -p /writeable/tomcat
cp -dRv "${AM_CATALINA_HOME}/." /writeable/tomcat/
