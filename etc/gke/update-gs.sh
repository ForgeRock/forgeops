#!/usr/bin/env bash
# Updates permissions on gcr.io buckets
GS=gs://artifacts.engineering-devops.appspot.com/

gsutil defacl ch -u AllUsers:R $GS

gsutil -m acl ch -r -u AllUsers:R $GS

gsutil -m acl ch -u AllUsers:R $GS