#!/bin/sh

if [ -d /fbc/conf ]; then
  echo "Existing openidm configuration found. Skipping copy."
elif [ -d /custom/config ]; then
  echo "Found config in custom volume."
  cd /opt/openidm
  cp -rv ui conf script /fbc
  # Deployer-provided configuration wins: drop the pristine-conf marker so
  # the image's apply-config-profile.sh never overlays the profile on top.
  rm -f /fbc/conf/.pristine-zip-conf
  cp -av /custom/config/* /fbc/
else
  echo "Copying docker image configuration files to the shared volume"
  cd /opt/openidm
  cp -rv ui conf script /fbc
fi

# Single-image runtime mode: when the deployment runs the image in forgeops
# mode, apply the CONFIG_PROFILE deployment conf over the conf the main
# container will read (the fbc volume). Pass /fbc as the home so the overlay
# lands in /fbc/conf; the helper is a no-op unless IMAGE_MODE=forgeops and
# the conf is still the pristine maven-build conf. The standalone (no fbc
# volume) path is covered by the image entrypoint calling the same helper
# with the default home.
if [ -d /fbc ]; then
  /opt/openidm/bin/apply-config-profile.sh /fbc || true
fi

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /opt/openidm"
mkdir -p /writeable/opt
cp -av /opt/openidm/ /writeable/opt/openidm
