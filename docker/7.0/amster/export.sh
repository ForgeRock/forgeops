#!/usr/bin/env bash
# Does a one shot export of the AM configuration. This assumes the project has already been checked out.

rm -fr /var/tmp/amster
mkdir -p /var/tmp/amster

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa http://am:80/am
export-config --path /var/tmp/amster
:quit
EOF


/opt/amster/amster /tmp/do_export.amster
