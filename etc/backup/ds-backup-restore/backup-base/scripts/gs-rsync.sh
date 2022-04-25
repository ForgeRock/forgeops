#!/usr/bin/env bash
# $1 - source  $2 destination
gsutil -o "GSUtil:state_dir=/tmp/gsutil" -m rsync -r $1 $2
