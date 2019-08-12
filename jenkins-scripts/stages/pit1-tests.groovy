/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun, String scope) {

    pipelineRun.pushStageOutcome('pit1', stageDisplayName: 'Run PIT1 FTs') {
        node('google-cloud') {
            dir('forgeops') {
                unstash 'workspace'
            }

            stage('Run PIT1 FTs') {
                pipelineRun.updateStageStatusAsInProgress()
                dir('lodestar') {
                    def cfg = [
                            TESTS_SCOPE      : scope,
                            SAMPLE_NAME      : 'smoke-deployment',
                            SKIP_FORGEOPS    : 'True',
                            EXT_FORGEOPS_PATH: "${env.WORKSPACE}/forgeops"
                    ]

                    commonModule.determinePitOutcome("${env.BUILD_URL}/Allure_20Report_20Run_5fPIT1_5fFTs/") {
                        withGKEPitNoStages(cfg)
                    }
                }
            }
        }
    }
}

return this
