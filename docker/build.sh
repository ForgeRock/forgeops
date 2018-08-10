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

#REGISTRY="forgerock-docker-internal.bintray.io"

REPO="forgerock"
# Default tag if none is specified.
TAG=${TAG:-6.5.0-M0}

# If you want to push to Google gcr.io, replace the repository name with your project name.
PROJECT="engineering-devops"

# These are the default images that will be built if no images are specified on the command line.
IMAGES="openam ds openidm openig amster util git java gatling apache-agent nginx-agent"

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

   CF=""
   if [ -n "$CACHE_FROM" ]; then
    CF="--cache-from $CACHE_FROM/$1:${TAG}"
   fi

   eval ${DRYRUN}  docker build $NETWORK "$CF" -t ${REGISTRY}/${REPO}/$1:${TAG}${SNAPSHOT} $1
   if [ -n "$PUSH" ]; then
      ${DRYRUN} docker push ${REGISTRY}/${REPO}/$1:${TAG}${SNAPSHOT}
   fi
}

# --cache-from multistage issue: https://github.com/moby/moby/issues/34715
while getopts "adgpst:r:R:P:i:c:n:" opt; do
  case ${opt} in
    a ) AUTHENTICATE="true" ;;
    t ) TAG="${OPTARG}" ;;
    s ) SNAPSHOT="-SNAPSHOT" ;;
    d ) DRYRUN="echo" ;;
    r ) REGISTRY="${OPTARG}" ;;
    R ) REPO="${OPTARG}" ;;
    g ) REGISTRY="gcr.io" && REPO="${PROJECT}" ;;
    P ) PROJECT="${OPTARG}" && REPO="${PROJECT}" ;;
    i ) INCREMENTAL="${OPTARG}" ;;
    c ) CACHE_FROM="${OPTARG}" ;;
    n ) NETWORK="--network=${OPTARG}" ;;
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
         echo "-i N - incrementally build only containers that changed in the last N commits"
         echo "-c prefix - add --cache-from $prefix/$image:$tag to the docker build"
         exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ ! -z "$INCREMENTAL" ]; then
  IMAGES=`git diff --name-only "HEAD..HEAD~$INCREMENTAL" | sort -u  | grep "docker/" | awk 'BEGIN {FS="/"} {print $2}' | uniq`
  echo "Incremental build: $IMAGES"
  if [ -z "$IMAGES" ]; then
    echo "No images changed in the last $INCREMENTAL commits"
    exit 0
  fi
fi

# Test for the forgerock downloader image - needed to download bits

DL=`docker images -q forgerock/downloader`

if [ -z "$DL" ]; then 
  echo "Can't find forgerock/downloader image needed to download ForgeRock binaries. I will attempt to build it"
  if [ -z "$API_KEY" ]; then
    echo "Artifactory API_KEY environment variable is not set. You must export API_KEY=your_artifactory_api_key"
    exit 1
  fi
  docker build -t forgerock/downloader --build-arg API_KEY=$API_KEY downloader
fi 



if [ "$#" -eq "0" ]; then
   for image in $IMAGES; do
      buildDocker $image
   done
else
   echo "Building $@"
   buildDocker $@
fi
