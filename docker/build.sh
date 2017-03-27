#!/usr/bin/env bash
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Build Docker images.
# Usage:  Run ./build.sh -?
# Note: This script assumes the relevant binary war files and zip files have been downloaded
# and moved to the correct locations (example: openam/openam.war).

# Default environment variables. You can set these all via command switches as well.
REGISTRY=""
REPO=${REPO:-forgerock}
# Default tag if none is specified.
TAG=${TAG:-latest}

# If you want to push to Google gcr.io, replace the repository name with your project name.
PROJECT="engineering-devops"

# These are the default images that will be built if no images are specified on the command line.
IMAGES="openam opendj openidm openig amster"

function buildDocker {
   SLASH="/"
   if [[ ! -z $REGISTRY ]]
   then
     BUILD_REGISTRY=${REGISTRY}${SLASH}
   else
     BUILD_REGISTRY=${REGISTRY}
   fi
   ${DRYRUN}  docker build -t ${BUILD_REGISTRY}${REPO}/$1:${TAG} $1
   if [ -n "$PUSH" ]; then
      ${DRYRUN} ${GCLOUD} docker ${CMD_SEP} push ${BUILD_REGISTRY}${REPO}/$1:${TAG}
   fi
}

while getopts "dgpt:r:R:P:" opt; do
  case ${opt} in
    t ) TAG="${OPTARG}" ;;
    d ) DRYRUN="echo" ;;
    r ) REGISTRY="${OPTARG}" ;;
    R ) REPO="${OPTARG}" ;;
    g ) GCLOUD="gcloud" && PUSH="1" && REGISTRY="gcr.io" && CMD_SEP="--" && REPO="${PROJECT}" ;;
    P ) PROJECT="${OPTARG}" && REPO="${PROJECT}" ;;
    p ) PUSH="1" ;;
    \? )
         echo "Usage: build [-p] [-g] [-t tag] [-r registry] [-R repo] [-G project] image1 ..."
         echo "-p Push images to registry after building."
         echo "-g Push images to the Google gcr.io registry."
         echo "-P project  - Set the Google project id if using gcr.io. Default $PROJECT"
         echo "-R Set the repository name. Default $REPO"
         echo "-r Set the Registry. Default $REGISTRY"
         echo "-t tag - Tag the docker image image (default $TAG)"
         echo "-d dry run. Don't do the docker build/push, just show what would be done."
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