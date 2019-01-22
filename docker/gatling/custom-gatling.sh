#!/bin/bash
# Custom gatling runtime script
# Useful for making it easier to pass arguments to gatling from helm charts
#
# Copyright (c) 2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file


while getopts j:i:g: option
do
 case "${option}"
 in
 j) JAVA_OPTIONS=${OPTARG};;
 i) CMD_OPTIONS=${OPTARG};;
 g) GATLING_ARGS=${OPTARG};;
 esac
done

GATLING_READY_FILE="/ready"

counter=0
continue_looping=true
while [ "${continue_looping}" = "true" ] && [ ${counter} -lt 120 ]
do
    echo "Loop n.${counter}"
    if [ -e "${GATLING_READY_FILE}" ]
    then
        echo "READY to run gatling.sh"
        continue_looping=false
    else
        echo "NOT READY to run gatling.sh - ready file ${GATLING_READY_FILE} not found"
        counter=$((counter+1))
        sleep 2
    fi
done

if [ "${continue_looping}" = "true" ]
then
    echo "# FAIL - ready file ${GATLING_READY_FILE} not found after 30 loops"
    exit 1
fi

echo ""
echo "----------------------------"
echo "Provided script parameters:"
echo "java_options:${JAVA_OPTIONS}"
echo "cmd_options:${CMD_OPTIONS}"
echo "tests to run: ${TESTS}"
echo "----------------------------"
echo ""
echo "Starting gatling simulation"

# set java options for gatling
export JAVA_OPTS="${JAVA_OPTIONS}"

# handle CMD_OPTIONS and in case there are some replace the gatling.sh file
if [ -n "${CMD_OPTIONS}" ]
then
    echo ""
    echo "----------------------------"
    echo "CMD_OPTIONS is not empty => modifying gatling.sh"
    echo "----------------------------"
    sed -i -e "s/ io.gatling.app.Gatling/ ${CMD_OPTIONS} io.gatling.app.Gatling/g" /opt/gatling/bin/gatling.sh
fi
# Workaround for running multiple tests. A list of tests(whitespace separated string with test names) is parsed
# and gatling is run multiple times
for test in $TESTS; do 
    RUN_ARG=$(sed "s/TESTNAME/$test/g" <<< ${GATLING_ARGS})
    echo ""
    echo "----------------------------"
    echo "GATLING COMMAND: gatling.sh ${RUN_ARG}"
    echo "----------------------------"

    gatling.sh ${RUN_ARG}    
done


