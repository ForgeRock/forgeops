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
    node('perf-cloud') {
        def forgeopsPath = localGitUtils.checkoutForgeops()

        def config_common = [
                STASH_LODESTAR_BRANCH   : commonModule.LODESTAR_GIT_COMMIT,
                EXT_FORGEOPS_PATH       : forgeopsPath,
                CLUSTER_DOMAIN          : 'pit2-perf.forgeops.com',
                PIPELINE_NAME           : "ForgeOps-PIT2-promotion",
                CHECK_REGRESSION        : true,
                MAX_VARIATION           : '0.10',
        ]

        def parentStageName = 'PIT2 Perf'
        def tags = ['PIT2', 'performance']

        // perf platform test
        if (params.PIT2_Perf_platform.toBoolean()) {
            def stageName = "${parentStageName} platform"
            def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

            pipelineRun.pushStageOutcome([tags: tags, stageDisplayName: stageName], normalizedStageName) {
                stage(stageName) {
                    dir('lodestar') {
                        def stagesCloud = [:]
                        stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud('platform')

                        dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME   : 'platform',
                                    BASELINE_RPS: '[1983,1722,1136,360]',
                            ]

                            withGKEPyrockNoStages(config)
                        }

                        return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                    }
                }
            }
        }

        // perf am authn rest test
        if (params.PIT2_Perf_am_authn.toBoolean()) {
            def stageName = "${parentStageName} am_authn"
            def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

            pipelineRun.pushStageOutcome([tags: tags, stageDisplayName: stageName], normalizedStageName) {
                stage(stageName) {
                    dir('lodestar') {
                        def stagesCloud = [:]
                        stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud('authn_rest')

                        dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME   : 'authn_rest',
                                    BASELINE_RPS: '2550',
                            ]

                            withGKEPyrockNoStages(config)
                        }

                        return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                    }
                }
            }
        }

        // perf am access token test
        if (params.PIT2_Perf_am_access_token.toBoolean()) {
            def stageName = "${parentStageName} am_access_token"
            def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

            pipelineRun.pushStageOutcome([tags: tags, stageDisplayName: stageName], normalizedStageName) {
                stage(stageName) {
                    dir('lodestar') {
                        def stagesCloud = [:]
                        stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud('access_token')

                        dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME   : 'access_token',
                                    BASELINE_RPS: '[2733,2453]',
                            ]

                            withGKEPyrockNoStages(config)
                        }

                        return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                    }
                }
            }
        }

        // perf IDM CRUD on simple managed users tests
        if (params.PIT2_Perf_idm_crud.toBoolean()) {
            def stageName = "${parentStageName} idm_crud"
            def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

            pipelineRun.pushStageOutcome([tags: tags, stageDisplayName: stageName], normalizedStageName) {
                stage(stageName) {
                    dir('lodestar') {
                        def stagesCloud = [:]
                        stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud('simple_managed_users')

                        dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME   : 'simple_managed_users',
                                    BASELINE_RPS: '[5688,0,0,0,1803,3977,1274,955]',
                            ]

                            withGKEPyrockNoStages(config)
                        }

                        return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                    }
                }
            }
        }
    }
}

return this
