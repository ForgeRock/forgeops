#!/bin/sh
# The DS filesystem init, shared by the Debian and Alpine image lines (the
# DS layout is identical in both: /home/forgerock + /opt/opendj).

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /home/forgerock"
mkdir -p /writeable/home
# Copy with `cp -rv` (NOT -a): some image files may be root-owned, and
# busybox cp -a exits 1 when it cannot preserve ownership (GNU cp only
# warns). The init runs as the product uid, so plain -r ownership (files
# owned by the runner) is exactly right for the writeable volume.
cp -rv /home/forgerock/ /writeable/home/forgerock/
echo "Copying /opt/opendj"
mkdir -p /writeable/opt
cp -rv /opt/opendj/ /writeable/opt/opendj/
