/*
 * Copyright 2019-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */


import com.forgerock.pipeline.reporting.PipelineRun
import com.forgerock.pipeline.stage.FailureOutcome
import com.forgerock.pipeline.stage.Outcome
import com.forgerock.pipeline.stage.Status

void runStage(PipelineRun pipelineRun) {

    def stageName = 'PIT2 PERF'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('perf-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()

                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def config_common = [
                        STASH_LODESTAR_BRANCH   : commonModule.LODESTAR_GIT_COMMIT,
                        EXT_FORGEOPS_PATH       : forgeopsPath,
                        PIPELINE_NAME           : "ForgeOps-PIT2-promotion",
                    ]

                    def stagesCloud = [:]

                    // perf platform test
                    def subStageName = 'platform'
                    stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('platform')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def config = config_common.clone()
                        config += [
                            TEST_NAME       : "platform",
                        ]

                        withGKEPyrockNoStages(config)
                    }

                    // perf am authn rest test
                    subStageName = 'am_authn'
                    stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('authn_rest')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def config = config_common.clone()
                        config += [
                            TEST_NAME       : "authn_rest",
                        ]

                        withGKEPyrockNoStages(config)
                    }

                    // perf am access token test
                    subStageName = 'am_access_token'
                    stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('access_token')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def config = config_common.clone()
                        config += [
                            TEST_NAME       : "access_token",
                        ]

                        withGKEPyrockNoStages(config)
                    }

                    // IDM CRUD on simple managed users tests
                    subStageName = 'idm_crud'
                    stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('simple_managed_users')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def config = config_common.clone()
                        config += [
                            TEST_NAME       : "simple_managed_users",
                        ]

                        withGKEPyrockNoStages(config)
                    }

                    summaryReportGen.createAndPublishSummaryReport(stagesCloud, stageName, '', false,
                        normalizedStageName, "${normalizedStageName}.html")
                    return dashboard_utils.determineLodestarOutcome(stagesCloud,
                        "${env.BUILD_URL}/${normalizedStageName}/")
                }
            }
        }
    }
}

return this
