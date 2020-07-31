#!/usr/bin/env bash
# Copy from one registry to another

SRC="gcr.io/engineering-devops"
DEST="gcr.io/forgerock-io"
TAG="7.0.0"

if [ -n "$1" ];
    then TAG=$1
fi

IMAGES="openam ds openidm openig amster util git java"

for image in $IMAGES; do 
    docker pull $SRC/$image:$TAG 
    docker tag $SRC/$image:$TAG $DEST/$image:$TAG 
    docker push $DEST/$image:$TAG 
done