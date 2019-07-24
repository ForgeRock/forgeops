#!/usr/bin/env groovy

import com.forgerock.pipeline.reporting.PipelineRun
import com.forgerock.pipeline.stage.FailureOutcome
import com.forgerock.pipeline.stage.Status

void runStage(PipelineRun pipelineRun, String scope) {

    pipelineRun.pushStageOutcome('pit1', stageDisplayName: 'Run PIT #1 FTs') {
        node("google-cloud") {
            dir("forgeops") {
                unstash 'workspace'
            }

            stage("Run PIT1 FTs") {
                pipelineRun.updateStageStatusAsInProgress()
                dir("lodestar") {
                    def cfg = [
                            TESTS_SCOPE      : scope,
                            SAMPLE_NAME      : "smoke-deployment",
                            SKIP_FORGEOPS    : "True",
                            EXT_FORGEOPS_PATH: "${env.WORKSPACE}/forgeops"
                    ]

                    determinePitOutcome() {
                        withGKEPitNoStages(cfg)
                    }
                }
            }
        }
    }
}

def determinePitOutcome(Closure process) {
    try {
        process()
        return Status.SUCCESS.asOutcome()
    } catch (Exception e) {
        return new FailureOutcome(e)
    }
}

return this
