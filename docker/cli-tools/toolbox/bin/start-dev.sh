#!/usr/bin/env bash
# Experimental - WIP

DEV_DIR="$WORKSPACE/forgeops/kustomize/dev"


cd  "$DEV_DIR" || {
    echo "Could not cd to $DEV_DIR"
}


./start.sh

