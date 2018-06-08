#!/usr/bin/env bash
#
# Helper script to compose slack notification with test results
#
# Required vars
# - SLACK_SERVICE:
# - TEST_NAME
# - TEST_RESULTS_FILE: (PASS/FAIL)
# - LAST_COMMIT_FILE: Username of last user that merged code into master
# Optional vars
# - TEST_REPORT_LINK: URL to tests

if [ -z ${SLACK_SERVICE+x} ]; then
  echo "SLACK_SERVICE must be set"
  exit 0
fi

if [ -z ${TEST_NAME+x} ]; then
  echo "TEST_NAME must be set"
  exit 0
fi

if [ -z ${TEST_RESULTS_FILE+x} ]; then
  echo "TEST_RESULTS_FILE must be set"
  exit 0
fi

if [ -z ${LAST_COMMIT_FILE+x} ]; then
  echo "LAST_COMMIT must be set"
  exit 0
fi

if [ -z ${TEST_REPORT_LINK+x} ]; then
  TEST_REPORT_LINK="No report link"
fi


JSON_SLACK=$(cat <<EOF
{
  "mrkdwn": true,
  "text": "*${TEST_NAME} results*",
  "attachments": [
    {
      "text": "$(cat ${TEST_RESULTS_FILE})"
    },
		{
			"color": "good",
			"text": "Last commit by: $(cat ${LAST_COMMIT_FILE})"
		},
		{
			"color": "good",
			"text": "Link to report: ${TEST_REPORT_LINK}"
		}
  ]
}
EOF
)

curl --data-urlencode "payload=${JSON_SLACK}" ${SLACK_SERVICE}
