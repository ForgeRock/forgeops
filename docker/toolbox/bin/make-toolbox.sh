#!/usr/bin/env bash
# Make a docker toolbox
# Run this from the root directory - as we need the files to be in the docker build context

docker build -t forgerock/toolbox:latest -f docker/toolbox/Dockerfile  .



