#!/usr/bin/env bash
# restore from gcs storage

# TODO: If you want to pull from ldif folders by date this is the place to do it.

# The source of the data to restore. This will be have been placed on the disk by the
# previous container.

DST=${1:-/data/$NAMESPACE}

mkdir -p $DST

GCS_PATH=${GCS_PATH:-"gs://forgeops/ds-backup/$NAMESPACE"}

set -x

gsutil -o "GSUtil:state_dir=/tmp/gsutil" ls -R $GCS_PATH

# The GSUtil trick is to avoid gsutil writing to /.gsutil and getting a permission error.
gsutil -o "GSUtil:state_dir=/tmp/gsutil" -m rsync -r $GCS_PATH $DST || exit 1

echo "Restored these files from gcs:"

ls -R $DST