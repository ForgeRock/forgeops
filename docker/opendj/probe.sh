#!/usr/bin/env bash
# Sample shell script to check for readiness and liveness.
# Returns 0 on ready, non zero if DJ is not ready
nc -vz localhost 8081 && [ ! -f /opt/opendj/BOOTSTRAPPING ]