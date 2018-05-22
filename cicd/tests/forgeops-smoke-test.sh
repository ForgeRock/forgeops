#!/usr/bin/env bash
################################################################################
# ForgeOps smoke test suite
#
# Each test must set PASS=true/false and optionally RES with content that
# will be logged in debug.txt
#
# Exit code is 0 in case of success, 1 in case of any failure to notify
# CI/CD system of test failure
#
################################################################################

# Helper methods
usage() {
  echo "Forgeops smoke tests"
  echo "Usage: forgeops-smoke-test.sh [OPTIONS]"
  echo "  -s, --suite       test suite to run"
  echo "  -l, --list        list available test suites"
  echo "  -h, --help        show this help"
  echo ""
  echo "example usage: ./forgeops-smoke-test.sh -s am-smoke.sh"
}

list_suites() {
  echo -e "\e[32m$(ls testcases/)"
}

# Parameters parsing
if [[ $# -eq 0 ]] ; then
    usage
    exit 0
fi

POSITIONAL=()

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -s|--suite)
    SUITE="$2"
    shift
    shift
    ;;
    -l|--list)
    list_suites
    shift
    exit 0
    ;;
    -h|--help)
    usage
    shift
    exit 0
    ;;
    *)
    usage
    shift
    exit 1
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Test variables
PASSED=0
FAILED=0

# Reporting funcs
print_report() {
  echo ""
  echo ""
  echo -e "\e[33mForgeops smoke test suite report\e[39m"
  echo "----Summary----"
  echo -e "\e[32mPASSED: \e[39m$PASSED"
  echo -e "\e[31mFAILED: \e[39m$FAILED"
  echo ""
  echo "----Details----"
  cat out.txt
}


# Load test and config sources
source testcases/$SUITE
source config.cfg

# Global vars for tests
RES=""
PASS=false
TESTNAME=""

echo "=====Smoke test suite results=====" > out.txt
echo "Suite: $SUITE" >> out.txt
echo " "

# Testloop
for testc in "${tests[@]}"
do
  $testc
  echo .
  if [ $PASS = true ]; then
     let PASSED+=1
     echo "===================================" >> out.txt
     echo " - Test $TESTNAME - PASS" >> out.txt
  else
    let FAILED+=1
    echo "===================================" >> out.txt
    echo " - Test $TESTNAME - FAIL" >> out.txt
    echo " - Details:" >> out.txt
    echo "$RES" >> out.txt
  fi
  PASS=false
  RES=""
done
print_report

# RC handling
if [ $FAILED != 0 ]; then
  exit 1
else
  exit 0
fi
