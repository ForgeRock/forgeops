/*
 * Copyright 2020-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// perf-sprint-release-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun) {
    node('perf-long-cloud') {
        def config_common = [
                STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
                STASH_FORGEOPS_BRANCH: commonModule.FORGEOPS_GIT_COMMIT,
                PIPELINE_NAME        : 'ForgeOps - Perf-Sprint-Release',
                CHECK_REGRESSION     : true,
                MAX_VARIATION        : '0.10',
                CLUSTER_DOMAIN       : 'perf-sprint-release.forgeops.com',
                TIMEOUT              : '12',
                TIMEOUT_UNIT         : 'HOURS',
        ]

        def groupStageName = dashboard_utils.normalizeStageName('PERF Sprint Release')
        def tags = ['performance', 'sprint_release']

        // perf am authn rest test
        if (params.PerfSprintRelease_authn_rest.toBoolean()) {
            def stageName = "${groupStageName} am_authn"
            def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

            pipelineRun.pushStageOutcome([group : groupStageName, tags : tags, stageDisplayName : stageName],
                    normalizedStageName) {
                stage(stageName) {
                    dir('lodestar') {
                        def stagesCloud = [:]
                        stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud('authn_rest')

                        dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME                  : 'authn_rest',
                                    DEPLOYMENT_RESTOREBUCKETURL: 'gs://performance-bucket-us-east1/nemanja/3ds-10M-bis',
                                    DEPLOYMENT_MAKEBACKUP      : false,
                                    CONFIGFILE_NAME            : 'conf-stability.yaml',
                                    BASELINE_RPS               : '2550',
                            ]

                            withGKEPyrockNoStages(config)
                        }

                        return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                    }
                }
            }
        }

        // perf am access token test
        if (params.PerfSprintRelease_access_token.toBoolean()) {
            def stageName = "${groupStageName} am_access_token"
            def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

            pipelineRun.pushStageOutcome([group : groupStageName, tags : tags, stageDisplayName : stageName],
                    normalizedStageName) {
                stage(stageName) {
                    dir('lodestar') {
                        def stagesCloud = [:]
                        stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud('access_token')

                        dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME                  : 'access_token',
                                    DEPLOYMENT_RESTOREBUCKETURL: 'gs://performance-bucket-us-east1/nemanja/3ds-10M-bis',
                                    DEPLOYMENT_MAKEBACKUP      : false,
                                    BASELINE_RPS               : '[2733,2453]',
                                    CONFIGFILE_NAME            : 'conf-stability.yaml',
                            ]

                            withGKEPyrockNoStages(config)
                        }

                        return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                    }
                }
            }
        }

        // perf platform test
        if (params.PerfSprintRelease_platform.toBoolean()) {
            def stageName = "${groupStageName} platform"
            def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

            pipelineRun.pushStageOutcome([group : groupStageName, tags : tags, stageDisplayName : stageName],
                    normalizedStageName) {
                stage(stageName) {
                    dir('lodestar') {
                        def stagesCloud = [:]
                        stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud('platform')

                        dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME                  : 'platform',
                                    DEPLOYMENT_RESTOREBUCKETURL: 'gs://performance-bucket-us-east1/nemanja/platform-backup',
                                    DEPLOYMENT_MAKEBACKUP      : false,
                                    BASELINE_RPS               : '[1983,1722,1136,360]',
                                    CONFIGFILE_NAME            : 'conf-restore-1m-stability.yaml'
                            ]

                            withGKEPyrockNoStages(config)
                        }

                        return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                    }
                }
            }
        }

        // perf IDM Crud test
        if (params.PerfSprintRelease_simple_managed_users.toBoolean()) {
            def stageName = "${groupStageName} idm_crud"
            def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

            pipelineRun.pushStageOutcome([group : groupStageName, tags : tags, stageDisplayName : stageName],
                    normalizedStageName) {
                stage(stageName) {
                    dir('lodestar') {
                        def stagesCloud = [:]
                        stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud('simple_managed_users')

                        dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME                  : 'simple_managed_users',
                                    CONFIGFILE_NAME            : 'conf-restore-backup-1m-stability.yaml',
                                    DEPLOYMENT_RESTOREBUCKETURL: 'gs://performance-bucket-us-east1/tinghua/1m',
                                    DEPLOYMENT_MAKEBACKUP      : false,
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
