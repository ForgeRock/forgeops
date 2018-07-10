#!/usr/bin/env bash
# delete untagged images

REPO=gcr.io/engineering-devops

for image in `gcloud container images list`; do
    echo $image
    for digest in `gcloud container images list-tags $image --filter='-tags:*'  --format='get(digest)' --limit=1000`; do
        echo "Deleting digest $digest"
        gcloud container images delete --quiet "${image}@${digest}"
    done
done