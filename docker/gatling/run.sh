#!/usr/bin/env bash

# Global
export TARGET_HOST="${TARGET_HOST:-smoke.iam.forgeops.com}"
export USER_POOL="${USER_POOL:-1000}" # User pool size.
export DURATION="${DURATION:-60}" # Duration of each simulation in seconds
export CONCURRENCY="${CONCURRENCY:-50}" # Number of concurrent users for each simulation

# Gradle options
G_OPTS="--no-daemon"

usage() {
    echo ""
    echo "Usage: run-all.sh [am|idm|platform]"
    echo ""
}

if [ $# -ne 1 ]; then 
	usage
	exit
fi

case $1 in

  am)
    export USER_PREFIX=user.
	export USER_PASSWORD=T35tr0ck123
	export oauth2_client_id="clientOIDC_0"
	export oauth2_redirect_uri="http://fake.com"
	gradle clean
	gradle "$G_OPTS" gatlingRun-am.AMRestAuthNSim
	gradle "$G_OPTS" gatlingRun-am.AMAccessTokenSim
    ;;

  idm)
    export DELETE_USERS="true" # Delete the IDM users before running create users
	export CLIENT_ID=idm-provisioning
	export CLIENT_PASSWORD=vtt3qtncd1dabsvq7ikehm11expywabq
	export IDM_USER=amadmin
	export IDM_PASSWORD=pw3j9uzgkx187fphchdzzxid48dridqa
	export USER_PREFIX=idmuser.
	gradle clean
	gradle "$G_OPTS" gatlingRun-idm.IDMSimulation
    ;;

  platform)
    export CLIENT_ID=idm-provisioning
	export CLIENT_PASSWORD=vtt3qtncd1dabsvq7ikehm11expywabq
	export IDM_USER=amadmin
	export IDM_PASSWORD=pw3j9uzgkx187fphchdzzxid48dridqa
	export USER_PREFIX=platuser.
	gradle clean
	gradle "$G_OPTS" gatlingRun-platform.Register
	gradle "$G_OPTS" gatlingRun-platform.Login
    ;;

  *)
    usage
    ;;

esac



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

