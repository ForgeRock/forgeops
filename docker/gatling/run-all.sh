#!/usr/bin/env bash

# Delete the IDM users before running create users
export DELETE_USERS="false"

export TARGET_HOST="${TARGET_HOST:-smoke.iam.forgeops.com}"
# User pool size. The benchmark needs at least this many sample users loaded in the user store.
export USER_POOL="${USER_POOL:-1000}"
# Duration of each simulation in seconds
export DURATION="${DURATION:-60}"
# Number of concurrent users for each simulation
export CONCURRENCY="${CONCURRENCY:-50}"

# Gradle options
G_OPTS="--no-daemon"
# We compile the binary in the docker build - so the clean is not stricly needed here
#gradle clean
# The idm simulation creates test users. Subsequent tests need these users!

#gradle "$G_OPTS" gatlingRun-idm.IDMReadCreateUsersSim65
#gradle "$G_OPTS" gatlingRun-idm.IDMDeleteUsersSim65
gradle "$G_OPTS" gatlingRun-idm.IDMSimulation70
gradle "$G_OPTS" gatlingRun-am.AMRestAuthNSim
gradle "$G_OPTS" gatlingRun-am.AMAccessTokenSim


# Note the google storage library needs a service account to upload results
# The env variable must be set:
# export GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json
# The service account needs permission to write / update the cloud storage bucket.
if [ -r "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo 'Uploading results'
  # For reasons unknown, the google storage library does not want to read
  # this file from a sym link (which is what a k8s secret is..)
  # So we need to make a copy of the file, and update the env var to point to it.
  cp  "$GOOGLE_APPLICATION_CREDENTIALS"  ./key.json
  export GOOGLE_APPLICATION_CREDENTIALS=key.json
  gradle "$G_OPTS" uploadResults
fi

