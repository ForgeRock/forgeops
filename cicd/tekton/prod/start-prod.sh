#!/usr/bin/env bash
# Kick off the nightly manually
tkn -n tekton-pipelines pipeline start prod-pipeline -s tekton-worker
