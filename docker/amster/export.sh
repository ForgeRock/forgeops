#!/usr/bin/env bash
# Does a one shot export of the AM configuration. This assumes the project has already been checked out.

mkdir -p "${EXPORT_PATH}"

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa http://openam/
export-config --path $EXPORT_PATH
:quit
EOF


/opt/amster/amster /tmp/do_export.amster
