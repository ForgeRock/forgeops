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
AM_VERSION=$VERSION-M9
IDM_VERSION=$VERSION-M7
DJ_VERSION=$VERSION-RC1
IG_VERSION=$VERSION-M125


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

dl() {
    echo "Downloading $1 to $2"


    if [ -z "${WGET}" ]
    then
        curl -s -H "$HEADER"  $1 -o $2
    else
        wget -q --header "$HEADER" $1  -O $2
    fi
}


dl_snapshots() {
    dl $AMSTER_SNAPSHOT amster/amster.zip
    dl $AM_SNAPSHOT openam/openam.war
    dl $IDM_SNAPSHOT openidm/openidm.zip
    dl $IG_SNAPSHOT openig/openig.war
    dl $DJ_SNAPSHOT opendj/opendj.zip
}

dl_milestones() {
    dl $AMSTER amster/amster.zip
    dl $AM openam/openam.war
    dl $IDM openidm/openidm.zip
    dl $IG openig/openig.war
    dl $DJ opendj/opendj.zip
}

while getopts "sw" opt; do
  case ${opt} in
    s ) BUILD_SNAPSHOTS="true" ;;
    w ) WGET="true" ;;
    \? )
         echo "Usage: dl.sh [-s]"
         echo "-s download snapshots instead of releases"
         echo "-w Use wget instead of curl"
         exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ ! -z "$BUILD_SNAPSHOTS" ]
then
    echo "Downloading snapshots"
    dl_snapshots
else
    echo "Downloading releases/milestones"
    dl_milestones
fi
