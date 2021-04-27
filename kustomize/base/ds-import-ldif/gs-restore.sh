#!/usr/bin/env bash
# restore from gcs storage

# TODO: If you want to pull from ldif folders by date this is the place to do it.

mkdir -p /data/ldif


# The GSUtil trick is to avoid gsutil writing to /.gsutil and getting a permission error.
gsutil -o "GSUtil:state_dir=/tmp/gsutil" -m rsync -r -d gs://forgeops/ldif-export /data/ldif/

echo "Restored these files from gcs:"

ls -R /data/ldif
