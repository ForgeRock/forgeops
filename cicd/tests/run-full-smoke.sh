#!/usr/bin/env bash

/tmp/forgeops-smoke-test.sh -s am-smoke.sh
AM_RC=$?
/tmp/forgeops-smoke-test.sh -s ig-smoke.sh
IG_RC=$?
/tmp/forgeops-smoke-test.sh -s idm-smoke.sh
IDM_RC=$?

echo "========================================================================="
echo "Smoke tests finished"
echo "========================================================================="

if [ ${AM_RC} -eq 0 ]; then
  echo "AM Tests: PASSED"
else
  echo "AM Tests: FAILED"
fi

if [ ${IG_RC} -eq 0 ]; then
  echo "IG Tests: PASSED"
else
  echo "IG Tests: FAILED"
fi

if [ ${IDM_RC} -eq 0 ]; then
  echo "IDM Tests: PASSED"
else
  echo "IDM Tests: FAILED"
fi

echo "========================================================================="
