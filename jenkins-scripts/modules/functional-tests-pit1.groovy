#!/usr/bin/env groovy

void runStage(String scope) {

    node("google-cloud") {
        dir("forgeops") {
            unstash 'workspace'
        }

        stage("Run PIT1 FTs") {
            dir("lodestar") {
                def cfg = [
                    TESTS_SCOPE      : scope,
                    SAMPLE_NAME      : "smoke-deployment",
                    SKIP_FORGEOPS    : "True",
                    EXT_FORGEOPS_PATH: "${env.WORKSPACE}/forgeops"
                ]

                withGKEPitNoStages(cfg)
            }
        }
    }
}

return this