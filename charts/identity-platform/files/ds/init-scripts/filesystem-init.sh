#!/bin/sh
# The DS filesystem init, shared by the Debian and Alpine image lines (the
# DS layout is identical in both: /home/forgerock + /opt/opendj).

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /home/forgerock"
mkdir -p /writeable/home
# `cp -dRv` (NOT -a): -a implies -p (preserve mode/ownership), which busybox
# cp cannot honor as the init's non-root uid and warns per file ("can't
# preserve ownership") — noise on every boot. -d/-P (preserve symlinks) is
# already busybox's default with -R, but stating it keeps GNU cp — where the
# default depends on build config — behaving identically. -R recurses; both
# busybox cp and GNU cp support the -dR pair.
cp -dRv /home/forgerock/ /writeable/home/forgerock/
echo "Copying /opt/opendj"
mkdir -p /writeable/opt
cp -dRv /opt/opendj/ /writeable/opt/opendj/
