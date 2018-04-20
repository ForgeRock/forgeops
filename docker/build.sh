#!/usr/bin/env bash
#
# Copyright (c) 2016-2017 ForgeRock AS. 
#
# Build Docker images.
# Usage:  Run ./build.sh -?
# Note: This script assumes the relevant binary war files and zip files have been downloaded
# and moved to the correct locations (example: openam/openam.war).

# Default settings. You can set these all via command switches as well.
REGISTRY="forgerock-docker-public.bintray.io"
REPO="forgerock"
# Default tag if none is specified.
TAG=${TAG:-6.0.0}

# If you want to push to Google gcr.io, replace the repository name with your project name.
PROJECT="engineering-devops"

# These are the default images that will be built if no images are specified on the command line.
IMAGES="openam opendj openidm openig amster util"

function buildDocker {

   if [[ ! -z "${AUTHENTICATE}" ]] ;
   then
       if  [[ -z "$DOCKER_USER" || -z "$DOCKER_PASSWORD" ]];
       then
            echo "Environment variable DOCKER_USER and DOCKER_PASSWORD not set"
            exit 1
       fi
       docker login -u "$DOCKER_USER" -p "$DOCKER_PASSWORD" "$REGISTRY"
   fi

   ${DRYRUN}  docker build -t ${REGISTRY}/${REPO}/$1:${TAG}${SNAPSHOT} $1
   if [ -n "$PUSH" ]; then
      ${DRYRUN} docker push ${REGISTRY}/${REPO}/$1:${TAG}${SNAPSHOT}
   fi
}

while getopts "adgpst:r:R:P:" opt; do
  case ${opt} in
    a ) AUTHENTICATE="true" ;;
    t ) TAG="${OPTARG}" ;;
    s ) SNAPSHOT="-SNAPSHOT" ;;
    d ) DRYRUN="echo" ;;
    r ) REGISTRY="${OPTARG}" ;;
    R ) REPO="${OPTARG}" ;;
    g ) REGISTRY="gcr.io" && REPO="${PROJECT}" ;;
    P ) PROJECT="${OPTARG}" && REPO="${PROJECT}" ;;
    p ) PUSH="1" ;;
    \? )
         echo "Usage: build [-p] [-g] [-t tag] [-r registry] [-R repo] [-G project] image1 ..."
         echo "-p Push images to registry after building."
         echo "-g Build images for the Google gcr.io registry."
         echo "-P project  - Set the Google project id if using gcr.io. Default $PROJECT"
         echo "-s Build SNAPSHOT images. Default $TAG-SNAPSHOT"
         echo "-R Set the repository name. Default $REPO"
         echo "-r Set the Registry. Default $REGISTRY"
         echo "-t tag - Tag the docker image (default $TAG)"
         echo "-d dry run. Don't do the docker build/push, just show what would be done."
         echo "-a authenticate to the registry using API_KEY environment variable."
         exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ "$#" -eq "0" ]; then
   for image in $IMAGES; do
      buildDocker $image
   done
else
   echo "Building $@"
   buildDocker $@
fi