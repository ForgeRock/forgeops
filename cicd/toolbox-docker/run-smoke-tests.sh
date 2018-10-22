#!/usr/bin/env bash
# Work in progress !
# Assumes forgeops source is checked out to /workspace/forgeops
WORKSPACE=/workspace/forgeops

REPORTS=/content/reports
LOGS=/content/logs
# Namespace is provided in $1

clean_ns() {
    echo "Cleaning up older deployments"
    kubens $1
    cd $WORKSPACE
    ./bin/remove-all.sh -N smoke
    kubectl delete secret frconfig
    kubectl delete configmap frconfig
    echo "Sleeping for 60 seconds to let namespace clean up"
}

prepare_folders() {
    if [ ! -d "$REPORTS" ]; then
        mkdir $REPORTS
    fi
    if [ ! -d "$LOGS" ]; then
        mkdir $LOGS
    fi
}

deploy_smoke() {
    cd $WORKSPACE
    echo "deploying the smoke test configuration"
    ./bin/deploy.sh samples/config/smoke-deployment
}

run_tests() {
    # Run smoke tests
    echo "Running smoke tests"
    cd $WORKSPACE/cicd/forgeops-tests/
    rm -rf reports/*
    ./run-smoke-tests.sh

    # Modify report to contain last git commit revision + message
    git log -n 1 > git.cm.slack
    echo "<pre>" > git.cm
    git log -n 1 >> git.cm
    echo "</pre>" >> git.cm

    # Update all new reports with git info
    mkdir tmp
    cp reports/* tmp/
    rm -rf reports/*
    FILES=tmp/*
    for f in $FILES
    do
        echo "Updating report files with git info"
        awk -v "var=$(cat git.cm)" '/<body>/ && !x {print var; x=1} 1' $f > reports/$(basename $f)
    done
    # Copy latest report to shared volume for dashboard to pick it up
    cp -r reports/* $REPORTS/
    # Clean up folders and logs older that week
    find $REPORTS/* -mtime +7 -exec rm -rf {} \;
    find $LOGS/* -mtime +7 -exec rm -rf {} \;
}

get_logs() {
    echo "Getting logs from smoke namespace"
    cd $WORKSPACE/bin
    NAMESPACE=$1 ./get-logs-from-ns.sh
    cp -r logs/* $LOGS/
    echo "Log collecion finished"
}

send_slack_notification() {
  echo "Sending notification"
  cd $WORKSPACE/cicd/forgeops-tests/

JSON_SLACK=$(cat <<EOF
  {
      "mrkdwn": true,
      "text": "*Forgeops smoke tests results* :${CLUSTER_NAME}",
      "attachments": [
        {
          "text": "$(cat results.txt)"
        },
        {
          "color": "good",
          "text": "*Link to dashboard:* ${TEST_REPORT_LINK}"
        },
        {
          "color": "good",
          "text": "*Last commit information:* $(cat git.cm.slack)"
        }
      ]
  }
EOF
)

  curl --data-urlencode "payload=${JSON_SLACK}" ${SLACK_SERVICE}

}

print_info() {
    echo "Finished testing..."
    exit 0
}

clean_ns smoke
prepare_folders
deploy_smoke
run_tests
get_logs smoke
send_slack_notification
print_info
