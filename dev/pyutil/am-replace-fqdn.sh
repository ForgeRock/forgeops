#!/usr/bin/env bash

echo "Replacing FQDN record in AM config"

if [ $# -eq 0 ]
  then
    echo "No FQDN provided. Please provide valid fqdn."
    exit 1
fi
FQDN=$1

echo "Replacing FQDN in following files:"
grep -rl --exclude-dir="*.git" default.iam.example.com am/openam/config 

grep -rl --exclude-dir="*.git" default.iam.example.com am/openam/config | xargs sed -i s^default.iam.example.com^$FQDN^g

