#!/usr/bin/env bash
#
# Copyright (c) 2016-2018 ForgeRock AS.
#
# Build Docker images.
#
# Usage:  Run ./build.sh -?
set -e
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

cd $DIR

# Default settings. You can set these all via command switches as well.
REGISTRY="forgerock-docker-public.bintray.io"
#REGISTRY="forgerock-docker-internal.bintray.io"

REPO="forgerock"
# Default tag if none is specified.
TAG=${TAG:-6.5.0}

# If you want to push to Google gcr.io, replace the repository name with your project name.
PROJECT="engineering-devops"

# These are the default images that will be built if no images are specified on the command line.
IMAGES="openam ds openidm openig amster util git java gatling apache-agent nginx-agent"

# --cache-from multistage issue: https://github.com/moby/moby/issues/34715
while getopts "adgpt:r:R:P:i:c:n:C:" opt; do
  case ${opt} in
    a ) if  [[ -z "$DOCKER_USER" || -z "$DOCKER_PASSWORD" ]];
       then
            echo "Environment variable DOCKER_USER and DOCKER_PASSWORD not set"
            exit 1
       fi
       # This is a bit kludgy - but we are hard coding the login to both bintray registires
       docker login -u "$DOCKER_USER" -p "$DOCKER_PASSWORD" forgerock-docker-public.bintray.io
       docker login -u "$DOCKER_USER" -p "$DOCKER_PASSWORD" forgerock-docker-internal.bintray.io
        ;;
    t ) TAG="${OPTARG}" ;;
    d ) DRYRUN="echo" ;;
    r ) REGISTRY="${OPTARG}" ;;
    R ) REPO="${OPTARG}" ;;
    g ) REGISTRY="gcr.io" && REPO="${PROJECT}" ;;
    P ) PROJECT="${OPTARG}" && REPO="${PROJECT}" ;;
    i ) INCREMENTAL="${OPTARG}" ;;
    c ) CACHE_FROM="${OPTARG}" ;;
    n ) NETWORK="--network=${OPTARG}" ;;
    C ) BUILD_CSV="${OPTARG}" ;;
    p ) PUSH="1" ;;
    \? )
         echo "Usage: build [-p] [-g] [-t tag] [-r registry] [-R repo] [-G project] image1 ..."
         echo "-p Push images to registry after building."
         echo "-g Build images for the Google gcr.io registry."
         echo "-P project  - Set the Google project id if using gcr.io. Default $PROJECT"
         echo "-R Set the repository name. Default $REPO"
         echo "-r Set the Registry. Default $REGISTRY"
         echo "-t tag - Tag the docker image (default $TAG)"
         echo "-d dry run. Don't do the docker build/push, just show what would be done."
         echo "-a authenticate to the registry. Must set DOCKER_USER and DOCKER_PASSWORD environment variables."
         echo "-i N - incrementally build only containers that changed in the last N commits. EXPERIMENTAL"
         echo "-c prefix - add --cache-from $prefix/$image:$tag to the docker build. EXPERIMENTAL"
         echo "-C image.csv - use the csv file as the specification for building / tagging the images. See README.md"
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

# Take the build list from a CSV file..
if [ -n "$BUILD_CSV" ]; then  
  while IFS=, read -r folder artifact tags 
  do       
      ${DRYRUN} docker build  $NETWORK --build-arg VERSION=$artifact -t $folder $folder

      # For each registry we support ()
      # for reg in "gcr.io/engineering-devops"
      for reg in "gcr.io/engineering-devops" "forgerock-docker-public.bintray.io/forgerock" 
      do
          # We always tag with the artifact
          img="${reg}/${folder}:${artifact}"
          ${DRYRUN} docker tag $folder:latest "$img"
          # Additional tags
          for tag in $tags 
          do 
              img="${reg}/${folder}:${tag}"
              ${DRYRUN} docker tag $folder:latest $img
             
          done
          # Push all tags.
           if [ -n "$PUSH" ]; then
            ${DRYRUN} docker push "${reg}/${folder}"
          fi
      done
     

  done < "$BUILD_CSV"

  exit $?
fi

# Function to build a docker image - $1- folder to build
function buildDocker {

   CF=""
   if [ -n "$CACHE_FROM" ]; then
    CF="--cache-from $CACHE_FROM/$1:${TAG}"
   fi

   eval ${DRYRUN}  docker build $NETWORK "$CF" -t ${REGISTRY}/${REPO}/$1:${TAG} $1
   if [ -n "$PUSH" ]; then
      ${DRYRUN} docker push ${REGISTRY}/${REPO}/$1:${TAG}
   fi
}


if [ "$#" -eq "0" ]; then
   for image in $IMAGES; do
      buildDocker $image
   done
else
   echo "Building $@"
   buildDocker $@
fi
