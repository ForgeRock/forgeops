#!/usr/bin/env bash
# A sample shell script to manually submit a build to cloud builder. You need to be authenicated
# to the engineering-devops project.
#
# The first argument ois name of the csv file that contains the images to build. See the README.md for the format, or look in the
# csv/ folder for examples.
CSV_FILE=$1 

if [ ! -r "$CSV_FILE" ];
then
    echo "Missing CSV input file"
    exit 1
fi

# You must set the env vars below with the appropriate credentials for pulling images from Artifactory (API_KEY), and for 
# pushing to the docker hb
if [ -r ~/etc/env.sh ]; then 

    source ~/etc/env.sh
fi

gcloud builds submit --config build.yaml  \
    --substitutions=_ARTIFACTORY_API_KEY=$API_KEY,_DOCKER_USER=${DOCKER_USER},_DOCKER_PASSWORD=${DOCKER_PASSWORD},_CSV_FILE=$CSV_FILE .
