#!/usr/bin/env bash
# Kick off the prod manually
tkn -n tekton-pipelines pipeline start prod-pipeline -s tekton-worker
