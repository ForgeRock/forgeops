/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun, String stageName, boolean useSkaffold = false) {

    pipelineRun.pushStageOutcome(commonModule.normalizeStageName(stageName), stageDisplayName: stageName) {
        node('google-cloud') {
            dir('forgeops') {
                unstash 'workspace'
            }

            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()

                stagesCloud = [:]

                def subStageName = stageName
                stagesCloud = commonModule.addStageCloud(stagesCloud, subStageName, "latest-${subStageName}.html")

                def cfg = [
                    TESTS_SCOPE             : 'tests/platform_deployment',
                    DEPLOYMENT_NAME         : 'platform-deployment',
                    STASH_LODESTAR_BRANCH   : commonModule.LODESTAR_GIT_COMMIT,
                    SKIP_FORGEOPS           : 'True',
                    EXT_FORGEOPS_PATH       : "${env.WORKSPACE}/forgeops",
                    USE_SKAFFOLD            : useSkaffold
                ]

                dir('lodestar') {
                    commonModule.determineUnitOutcome(stagesCloud[subStageName]) {
                        withGKEPitNoStages(cfg)
                    }
                }

                summaryReportGen.createAndPublishSummaryReport(stagesCloud, stageName, "build&&linux", false, stageName, "${stageName.toLowerCase()}.html")
                return commonModule.determinePitOutcome(stagesCloud, "${env.BUILD_URL}/${stageName}/")
            }
        }
    }
}

return this
