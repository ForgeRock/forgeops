/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// pit2-perf-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun) {

    def stageName = 'PIT2 Perf'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('perf-cloud') {
            stage(stageName) {
                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def config_common = [
                        STASH_LODESTAR_BRANCH   : commonModule.LODESTAR_GIT_COMMIT,
                        EXT_FORGEOPS_PATH       : forgeopsPath,
                        PIPELINE_NAME           : "ForgeOps-PIT2-promotion",
                        CHECK_REGRESSION        : true,
                        MAX_VARIATION           : '0.10',
                    ]

                    def stagesCloud = [:]

                    if (params.PIT2_Perf_platform.toBoolean()) {
                        // perf platform test
                        def subStageName = 'platform'
                        stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('platform')

                        dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME   : "platform",
                                    BASELINE_RPS: '[1983,1722,1136,360]',
                            ]

                            withGKEPyrockNoStages(config)
                        }
                    }

                    if (params.PIT2_Perf_am_authn.toBoolean()) {
                        // perf am authn rest test
                        subStageName = 'am_authn'
                        stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('authn_rest')

                        dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME   : "authn_rest",
                                    BASELINE_RPS: '2550',
                            ]

                            withGKEPyrockNoStages(config)
                        }
                    }

                    if (params.PIT2_Perf_am_access_token.toBoolean()) {
                        // perf am access token test
                        subStageName = 'am_access_token'
                        stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('access_token')

                        dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME   : "access_token",
                                    BASELINE_RPS: '[2733,2453]',
                            ]

                            withGKEPyrockNoStages(config)
                        }
                    }

                    if (params.PIT2_Perf_idm_crud.toBoolean()) {
                        // IDM CRUD on simple managed users tests
                        subStageName = 'idm_crud'
                        stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('simple_managed_users')

                        dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME   : "simple_managed_users",
                                    BASELINE_RPS: '[5688,0,0,0,1803,3977,1274,955]',
                            ]

                            withGKEPyrockNoStages(config)
                        }
                    }

                    return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                }
            }
        }
    }
}

return this
