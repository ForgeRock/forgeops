#!/usr/bin/env bash
# Send a notification message. This example uses Slack, but you can replace this
# with other notification methods.


if [ -z "$SLACK_URL" ] || [ "$SLACK_URL" = "undefined" ]
then
    echo "No slack url set"
    exit 0
fi

function post_to_slack () {
  # format message as a code block ```${msg}```
  SLACK_MESSAGE="\`\`\`$1\`\`\`"
  case "$2" in
    INFO)
      SLACK_ICON=':slack:'
      ;;
    WARNING)
      SLACK_ICON=':warning:'
      ;;
    ERROR)
      SLACK_ICON=':bangbang:'
      ;;
    *)
      SLACK_ICON=':slack:'
      ;;
  esac

  curl -s -X POST --data "payload={\"text\": \"${SLACK_ICON} ${SLACK_MESSAGE}\"}" ${SLACK_URL}
}

post_to_slack "$1" "$2"

