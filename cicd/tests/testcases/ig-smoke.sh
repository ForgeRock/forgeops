#!/usr/bin/env bash
################################################################################
# ForgeOps IG smoke tests definitions
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

# Ping test, expect HTTP-200 accessing default page
ping_test() {
  TESTNAME="IG ping test"
  RES=$(curl -v -LI $IG_URL/ \
          -o /dev/null -w '%{http_code}\n' -s)
  if [ "$RES" = "200" ]; then
    PASS=true
  fi
}


# Package funtions
tests=( ping_test )
