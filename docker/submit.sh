#!/usr/bin/env bash
# A sample shell script to manually submit a build to cloud builder. You need to be authenicated
# to the engineering-devops project.
#
# For example, to build AM from version 6.5.0-M3, and tag it with "foo", run this:
# ./submit.sh openam 6.5.0-M3,foo
#


mkdir -p tmp
CSV_FILE="tmp/build.csv"

# If there is one arg, assume it is a CSV file that we should submit to the builder
if [ $# = 1 ]; 
then
    CSV_FILE=$1
# else assume it is an docker image, an artifact name, and optional tags 
else
    cat >$CSV_FILE <<EOF
$1,$2
EOF
fi


if [ ! -r "$CSV_FILE" ];
then
    echo "Can't read CSV input file $CSV_FILE"
    exit 1
fi

# You must set the env vars below with the appropriate credentials for pulling images from Artifactory (API_KEY), and for 
# pushing to the docker hub
if [ -r ~/etc/env.sh ]; then 
    source ~/etc/env.sh
fi

echo "Submitting the following CSV file"
cat $CSV_FILE


gcloud builds submit --config build.yaml  \
    --substitutions=_ARTIFACTORY_API_KEY=$API_KEY,_DOCKER_USER=${DOCKER_USER},_DOCKER_PASSWORD=${DOCKER_PASSWORD},_CSV_FILE=$CSV_FILE .
