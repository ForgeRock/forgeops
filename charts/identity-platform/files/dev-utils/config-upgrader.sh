#!/usr/bin/env bash
# This script runs the config-upgrader against the provided path
# The "upgraded" config overwrites the source path.

# debug
# set -x
WORKSPACE="${WORKSPACE:-/git}"
REPO="fr-config"
REPO_SUBDIR="${REPO_SUBDIR:-am}"
CONFIG_DIR="${CONFIG_DIR:-config}"
REPO_PATH="$WORKSPACE/$REPO/$REPO_SUBDIR"
CONFIG_PATH="$REPO_PATH/$CONFIG_DIR"

[ ! -d "$REPO_PATH" ] && \
    echo "AM config volume mount not present at $REPO_PATH" && \
    exit 1
[ ! -d "$CONFIG_PATH/services" ] && \
    echo "AM config directory structure incorrect. Must be $CONFIG_PATH/services." && \
    exit 1

"$FORGEROCK_HOME/amupgrade/amupgrade" \
    --inputConfig $CONFIG_PATH/services \
    --output $CONFIG_PATH/services \
    --fileBasedMode \
    --prettyArrays \
    --clean false \
    --baseDn ou=am-config \
    $(ls -d /rules/*)

