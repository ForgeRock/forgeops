#!/usr/bin/env bash
# This performs an export of amster to the stdout in tar format
# Invoke this using kubectl. For example:
# kubectl exec amster-pod tar.sh | tar xvf - 
# Do not use the -it option on kubectl!
# This can take a long time to do the export - be patient.

rm -fr /var/tmp/amster

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa http://openam/
export-config --path /var/tmp/amster
:quit
EOF

# We need to redirect stdout/stderr so that tar doesn't try to ingest it
/opt/amster/amster /tmp/do_export.amster >/dev/null 2>&1 

cd  /var/tmp/amster
tar cf - . 
