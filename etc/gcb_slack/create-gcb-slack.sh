#!/usr/bin/env bash
# Enables slack notifications for cloud builder
# See https://cloud.google.com/container-builder/docs/configure-third-party-notifications


BUCKET_NAME=forgeops_cloudbuilds

gsutil mb gs://$BUCKET_NAME

cd gcb_slack

gcloud beta functions deploy subscribe --stage-bucket $BUCKET_NAME --trigger-topic cloud-builds
