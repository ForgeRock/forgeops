#!/usr/bin/env groovy

void runStage(String scope) {

    node("google-cloud") {
        stage("Run PIT1 FTs") {
            def cfg = [
                    TESTS_SCOPE         : "tests/smoke",
                    SAMPLE_NAME         : "smoke-deployment",
                    CLUSTER_IMAGE_TAG   : "7.0.0-latest-postcommit",
                    CLUSTER_IMAGE_LEVEL : "pit1",
                    SLACK_CHANNEL       : "#cloud-deploy-notify",
            ]

            withGKEPitNoStages(cfg)
        }
    }
}

return this