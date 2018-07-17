#!/usr/bin/env sh
# Script to download binaries from the ForgeRock Artifactory repository.
# This is used as part of a CI/CD process to build Docker images. If you are ForegeRock customer
# please download artifacts from BackStage and place them in the appropriate folders.

if [ -z "$API_KEY" ]
then
    echo "You must set the API_KEY environment variable"
    exit 1
fi

# Update major versions / snapshots here.

# Note: Until we get 6.5 milestones, we are using the 6.0.0 product images.
VERSION=${VERSION:-6.0.0}
SNAPSHOT=6.5.0-SNAPSHOT

# Update release / milestone / RC builds here.
AM_VERSION=$VERSION
IDM_VERSION=$VERSION
DJ_VERSION=$VERSION
IG_VERSION=$VERSION


# you should not need to edit the paths below
REPO=https://maven.forgerock.org/repo/internal-releases/org/forgerock
SNAPSHOT_REPO=https://maven.forgerock.org/repo/internal-snapshots/org/forgerock

WEB_AGENTS_SNAPSHOT_REPO=https://maven.forgerock.org/repo/forgerock-virtual/org/forgerock/openam/agents/web-agents/nightly
WEB_AGENTS_STABLE_REPO=https://maven.forgerock.org/repo/forgerock-virtual/org/forgerock/openam/agents/web-agents/5.0.1

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

NGINX_AGENT_SNAPSHOT=$WEB_AGENTS_SNAPSHOT_REPO/web-agents-nightly-NGINX_r12_Debian9_64bit.zip
NGINX_AGENT_STABLE=$WEB_AGENTS_STABLE_REPO/web-agents-5.0.1-NGINX_r12_Ubuntu16_64bit.zip

APACHE_AGENT_SNAPSHOT=$WEB_AGENTS_SNAPSHOT_REPO/web-agents-nightly-Apache_v24_Linux_64bit.zip
APACHE_AGENT_STABLE=$WEB_AGENTS_STABLE_REPO/web-agents-5.0.1-Apache_v24_Linux_64bit.zip

HEADER="X-JFrog-Art-Api: $API_KEY"


# Download a binary specified by $1
dl_binary() {

    # We supply both the snapshot source and the non snapshot source to the dl function
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
        dl $DJ_SNAPSHOT $DJ ds/opendj.zip
        ;;
    nginx-agent)
        dl $NGINX_AGENT_SNAPSHOT $NGINX_AGENT_STABLE nginx-agent/agent.zip
        ;;
    apache-agent)
        dl $APACHE_AGENT_SNAPSHOT $APACHE_AGENT_STABLE apache-agent/agent.zip
        ;;
    *)
        echo "Invalid image to downoad $1"
        exit 1
    esac
}

# Do the actual download. $1 - snapshot source $2 - release source, $3 destination
# Based on the value of -s argument, we download either the snapshot or the normal release
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

IMAGES="opendj openidm amster openam openig nginx-agent apache-agent"

while getopts "sw" opt; do
  case ${opt} in
    s ) BUILD_SNAPSHOTS="true" ;;
    w ) WGET="true" ;;
    \? )
         echo "Usage: dl.sh [-s] [-w] images..."
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
