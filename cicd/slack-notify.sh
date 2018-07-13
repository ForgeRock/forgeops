#!/usr/bin/env bash
#
# Helper script to compose slack notification with test results
#
# Required vars
# - SLACK_SERVICE - Webhook URL for slack notification
# - TEST_NAME - Name of test suite
# - TEST_RESULTS_FILE: Standart output of test run
# - LAST_COMMIT_FILE: File with last commit username
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
			"text": "Link to report: ${TEST_REPORT_LINK}"
		}
  ]
}
EOF
)

curl --data-urlencode "payload=${JSON_SLACK}" ${SLACK_SERVICE}
