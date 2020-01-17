#!/usr/bin/env bash
# Run the IDM and AM benchmarks for 6.5

# Delete the IDM users before running create users
export DELETE_USERS="false"

export TARGET_HOST="${TARGET_HOST:-smoke.iam.forgeops.com}"
# User pool size for IDM benchmarks
export USER_POOL="${USER_POOL:-1000000}"
# Duration of each simulation in seconds
export DURATION="${DURATION:-3600}"
# Number of concurrent users for each simulation
export CONCURRENCY="${CONCURRENCY:-50}"

# Gradle options
G_OPTS="--no-daemon"

# We compile the binary in the docker build - so the clean is not stricly needed here
gradle clean
# The simulations ending '65' are specifically for running against version 6.5.
# IDM does not authenticate with AM in 6.5

# Run the IDM 6.5 create/delete simulations.  These are independant of creating users for the AM simulations.
gradle "$G_OPTS" gatlingRun-idm.IDMReadCreateUsersSim65
gradle "$G_OPTS" gatlingRun-idm.IDMDeleteUsersSim65

# For the AM simulations, prefer users created by the DS make-users.sh script
# The uid format of those is user.$id
# If you want to use the IDM users created previously, comment out the USER_PREFIX - which
# will use the default testuser${id} format.
export USER_PREFIX="user."
# For the medium benchmark use 10M users for AM
export USER_POOL=10000000
gradle "$G_OPTS" gatlingRun-am.AMRestAuthNSim
gradle "$G_OPTS" gatlingRun-am.AMAccessTokenSim

# Optionally upload the benchmark results to GCS
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