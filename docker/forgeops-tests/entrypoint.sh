#!/usr/bin/env bash

# First time after deployment, run tests by default
./run-tests.sh

# Another test run have to be exectued by pinging service test endpoint. 
RESPONSE="HTTP/1.1 200 OK\r\n\r\n${2:-"Running tests"}\r\n"
while { echo -en "$RESPONSE"; } | nc -l -q 1 "${1:-8081}"; do
  echo "Rerunning tests"
  ./run-tests.sh
done