#!/usr/bin/env bash
# backup to gcs storage

GCS_PATH=${GCS_PATH:-gs://forgeops/ds-backup/$NAMESPACE}

SOURCE=/data/$NAMESPACE

# TODO: If you want to create ldif folders by date this is the place to do it.


# The GSUtil trick is to avoid gsutil writing to /.gsutil and getting a permission error.
# Adding -d will delete extra files found on GCS_PATH
gsutil -o "GSUtil:state_dir=/tmp/gsutil" -m rsync -r $SOURCE $GCS_PATH
