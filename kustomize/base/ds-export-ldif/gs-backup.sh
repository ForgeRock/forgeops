#!/usr/bin/env bash
# backup to gcs storage


# TODO: If you want to create ldif folders by date this is the place to do it.


# The GSUtil trick is to avoid gsutil writing to /.gsutil and getting a permission error.
gsutil -o "GSUtil:state_dir=/tmp/gsutil" -m rsync -r -d /data/ldif gs://forgeops/ldif-export



