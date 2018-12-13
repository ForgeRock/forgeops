#!/usr/bin/env bash

# A very simple script to prime the filesystem (page) cache with the directory database
# This script is mainly intended for benchmarking the userstore database
# Note it is not necessary that all *.jdb files will be cached.  It will depend on
# the OS, the free memory and various tuning parameters

cd /opt/opendj/db/amIdentityStore
ls -1 *.jdb | while read f
do
  dd if=${f} of=/dev/null bs=1M
done
