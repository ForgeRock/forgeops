#!/usr/bin/env bash
shopt -s globstar
set -o errexit -o pipefail
set -x

usage() {

read -r -d '' help <<-EOF

NAME
    Set ForgeOps Docker Version

    A script that enables quick source image changes for ForgeRock Dockerfiles

SYNOPSIS
    setDockerVersion.sh [OPTIONS] PRODUCT IMAGE [SOURCE]

DESCRIPTION
    Set PRODUCT base image to IMAGE [SOURCE IMAGE PATTERN]

    Options
        -h/--help
            print this message
        -n/--dry-run
            print changes, dont update file

    Mandatory arguments
        PRODUCT
            am, ds, idm, ig, must match a product in docker/7.0

        IMAGE
            gcr.io/forgerock-io/am/mypr:v8.7 base product image

    Optional arguments
        SOURCE
            gcr.io/forgerock-io/* sed pattern to change from to new image name

Examples:
    # change AM to be based on image in forgeop-public registry
    setDockerVersion.sh am gcr.io/forgeops-public/am:nightly
EOF

    printf "%-10s" "$help"
}

updateProductImage () {
    sed_str="s@FROM gcr.io/forgerock-io.*@FROM ${NEW_IMAGE_NAME}@g"
    sed_flags=""
    # add inplace arg if not dry run
    if [ ${DRY_RUN} -ne 1 ];
    then
            sed_flags+=" -i "
    fi
    # MacOS sed requires backup extension to be set
    if [[ "${OSTYPE}" == "darwin"* ]];
    then
        set_flags+=" '' "
    fi
    # Override source image pattern
    if [[ -z "${SOURCE_IMAGE}" ]];
    then
        set_str="s@FROM ${SOURCE_IMAGE}@FROM ${NEW_IMAGE_NAME}@g"
    fi
    # note we DO want to gob here so no quotes!
    sed "${sed_flags}${sed_str}" ${DOCKERFILE_PATH}
}

# handle flags
case "${1}" in
    -h|--help)
        usage
        exit;;
    -n|--dry-run)
        shift
        DRY_RUN=1;;
esac

# make sure we have two args
if [[ "${#}" -lt 2 ]];
then
    usage
    exit 1;
fi

# Setup Vars
SCRIPT_NAME=${0}
DOCKERFILE_PATH=docker/7.0/${1}/**/Dockerfile
NEW_IMAGE_NAME=${2}
SOURCE_IMAGE=${3}

# there's a match for the pattern
if ! compgen -G ${DOCKERFILE_PATH};
then
    echo "${1} has no Dockerfiles";
    exit 1;
fi

# image set
if [[ -z "${NEW_IMAGE_NAME}" ]];
then
    echo "New Image Argument Required";
    exit 1;
fi

# execute change
updateProductImage
