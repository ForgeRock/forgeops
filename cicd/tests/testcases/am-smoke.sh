#!/usr/bin/env bash
################################################################################
# ForgeOps AM smoke tests definitions
#
# This suite cointains a set of smoke tests that are intended to be run
# as part of CI/CD process.
#
# To run this tests, run ../forgeops-smoke-tests.sh -s am_smoke.sh
#
# Each testcase is going to be described inline
#
# Each test must set PASS=true/false and optionally RES with content that
# will be logged in out.txt
#
################################################################################

# Testcase definitions

# Ping test - Touch AM isAlive.jsp endpoint and expect HTTP-200
ping_test() {
  TESTNAME="AM ping test"
  RES=$(curl -v -LI $AM_URL/isAlive.jsp \
          -o /dev/null -w '%{http_code}\n' -s)
  if [ "$RES" = "200" ]; then
    PASS=true
  fi
}

# Admin login - Login into AM as Amadmin, expect tokenId to be present in resp.
admin_login_test() {
  TESTNAME="AM Login test"
  RES=$( curl --request POST --header \
    "Content-Type: application/json" \
    --header "Accept-API-Version: resource=2.0, protocol=1.0" \
    --header "X-OpenAM-Username: amadmin" \
    --header "X-OpenAM-Password: $AM_ADMIN_PWD" \
    $AM_URL/json/authenticate )

  if [[ $RES = *tokenId* ]]; then
    PASS=true
  else
    PASS=false
  fi
}

# User login - Login into AM as user, expect tokenId to be present in resp.
user_login_test() {
  TESTNAME="User Login test"
  RES=$( curl --request POST --header \
    "Content-Type: application/json" \
    --header "Accept-API-Version: resource=2.0, protocol=1.0" \
    --header "X-OpenAM-Username: user.1" \
    --header "X-OpenAM-Password: password" \
    $AM_URL/json/authenticate )

  echo $RES
  if [[ $RES = *tokenId* ]]; then
    PASS=true
  else
    PASS=false
  fi
}


# Package funtions
tests=(
  ping_test
  admin_login_test
  user_login_test
)
