#!/usr/bin/env bash
# Kick off the nightly manually
tkn -n tekton-pipelines pipeline start fidc-pipeline -s tekton-worker
