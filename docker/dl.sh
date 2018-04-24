#!/usr/bin/env sh
# Script to download binaries from ForgeRock Artifactory repository.

if [ -z "$API_KEY" ]
then
    echo "You must set the API_KEY environment variable"
    exit 1
fi

# Update major versions / snapshots here.
VERSION=6.0.0
SNAPSHOT=6.0.0-SNAPSHOT

# Update release / milestone / RC builds here.
AM_VERSION=$VERSION
IDM_VERSION=$VERSION
DJ_VERSION=$VERSION
IG_VERSION=$VERSION



# you should not need to edit the paths below
REPO=https://maven.forgerock.org/repo/internal-releases/org/forgerock
SNAPSHOT_REPO=https://maven.forgerock.org/repo/internal-snapshots/org/forgerock

AM=$REPO/am/openam-server/$AM_VERSION/openam-server-$AM_VERSION.war
AM_SNAPSHOT=$SNAPSHOT_REPO/am/openam-server/$SNAPSHOT/openam-server-$SNAPSHOT.war


AMSTER=$REPO/am/openam-amster/$AM_VERSION/openam-amster-$AM_VERSION.zip
AMSTER_SNAPSHOT=$SNAPSHOT_REPO/am/openam-amster/$SNAPSHOT/openam-amster-$SNAPSHOT.zip


IDM=$REPO/openidm/openidm-zip/$IDM_VERSION/openidm-zip-$IDM_VERSION.zip
IDM_SNAPSHOT=$SNAPSHOT_REPO/openidm/openidm-zip/$SNAPSHOT/openidm-zip-$SNAPSHOT.zip

DJ=$REPO/opendj/opendj-server/$DJ_VERSION/opendj-server-$DJ_VERSION.zip
DJ_SNAPSHOT=$SNAPSHOT_REPO/opendj/opendj-server/$SNAPSHOT/opendj-server-$SNAPSHOT.zip


IG=$REPO/openig/openig-war/$IG_VERSION/openig-war-$IG_VERSION.war
IG_SNAPSHOT=$SNAPSHOT_REPO/openig/openig-war/$SNAPSHOT/openig-war-$SNAPSHOT.war

HEADER="X-JFrog-Art-Api: $API_KEY"


# Download a binary specified by $1
dl_binary() {
    case "$1" in
    amster)
        dl $AMSTER_SNAPSHOT $AMSTER amster/amster.zip
        ;;
    openam)
        dl $AM_SNAPSHOT $AM openam/openam.war
        ;;
    openidm)
        dl $IDM_SNAPSHOT $IDM openidm/openidm.zip
        ;;
   openig)      
        dl $IG_SNAPSHOT $IG openig/openig.war
        ;;
    opendj)
        dl $DJ_SNAPSHOT $DJ opendj/opendj.zip
        ;;
    *) 
        echo "Invalid image to downoad $1"
        exit 1
    esac
}

# Do the actual download. $1 - snapshost source $2 - release source, $3 destination
dl(){
    if [ -z "$BUILD_SNAPSHOTS" ]; 
    then
        src="$2"
    else
        src="$1"
    fi

    echo "Downloading $src to $3"
    if [ -z "${WGET}" ]
    then
        curl --fail -s -H "$HEADER"  $src -o $3
    else
        wget -q --header "$HEADER" $src  -O $3
    fi

    if [ $? -ne 0 ] 
    then 
        echo "Download failed"
        exit 1
    fi
}

IMAGES="opendj openidm amster openam openig"

while getopts "sw" opt; do
  case ${opt} in
    s ) BUILD_SNAPSHOTS="true" ;;
    w ) WGET="true" ;;
    \? )
         echo "Usage: dl.sh [-s] images..."
         echo "-s download snapshots instead of releases"
         echo "-w Use wget instead of curl"
         echo "Images can be one or more of: $IMAGES"
         echo "If not specified, all images are downloaded"
         exit 1
      ;;
  esac
done
shift $((OPTIND -1))


if [ "$#" -ne 0 ]; then
   IMAGES="$@"
fi

for image in $IMAGES; do
      dl_binary $image
done