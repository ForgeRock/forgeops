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

    def stageName = 'PERF Sprint Release'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('perf-long-cloud') {
            stage(stageName) {
                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def config_common = [
                        STASH_LODESTAR_BRANCH   : commonModule.LODESTAR_GIT_COMMIT,
                        EXT_FORGEOPS_PATH       : forgeopsPath,
                        PIPELINE_NAME           : 'ForgeOps - Perf-Sprint-Release',
                        CHECK_REGRESSION        : true,
                        MAX_VARIATION           : '0.10',
                        CLUSTER_DOMAIN          : 'perf-sprint-release.forgeops.com',
                        TIMEOUT                 : '12',
                        TIMEOUT_UNIT            : 'HOURS',
                    ]

                    def stagesCloud = [:]
                    def subStageName = ''

                    if (params.PerfSprintRelease_authn_rest.toBoolean()) {
                        // perf am authn rest test
                        subStageName = 'am_authn_long'
                        stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('authn_rest')

                        dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME                  : "authn_rest",
                                    DEPLOYMENT_RESTOREBUCKETURL: 'gs://performance-bucket-us-east1/nemanja/3ds-10M-bis',
                                    DEPLOYMENT_MAKEBACKUP      : false,
                                    CONFIGFILE_NAME            : 'conf-stability.yaml',
                                    BASELINE_RPS               : '2550',
                            ]

                            withGKEPyrockNoStages(config)
                        }
                    }

                    if (params.PerfSprintRelease_access_token.toBoolean()) {
                        // perf am access token test
                        subStageName = 'am_access_token_long'
                        stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('access_token')

                        dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME                  : "access_token",
                                    DEPLOYMENT_RESTOREBUCKETURL: 'gs://performance-bucket-us-east1/nemanja/3ds-10M-bis',
                                    DEPLOYMENT_MAKEBACKUP      : false,
                                    BASELINE_RPS               : '[2733,2453]',
                                    CONFIGFILE_NAME            : 'conf-stability.yaml',
                            ]

                            withGKEPyrockNoStages(config)
                        }
                    }

                    if (params.PerfSprintRelease_platform.toBoolean()) {
                        // perf platform test
                        subStageName = 'platform_long'
                        stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('platform')

                        dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME                  : "platform",
                                    DEPLOYMENT_RESTOREBUCKETURL: 'gs://performance-bucket-us-east1/nemanja/platform-backup',
                                    DEPLOYMENT_MAKEBACKUP      : false,
                                    BASELINE_RPS               : '[1983,1722,1136,360]',
                                    CONFIGFILE_NAME            : 'conf-restore-1m-stability.yaml'
                            ]

                            withGKEPyrockNoStages(config)
                        }
                    }

                    if (params.PerfSprintRelease_simple_managed_users.toBoolean()) {
                        // perf IDM Crud test
                        subStageName = 'idm_crud_long'
                        stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('simple_managed_users')

                        dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                            def config = config_common.clone()
                            config += [
                                    TEST_NAME                  : "simple_managed_users",
                                    CONFIGFILE_NAME            : 'conf-restore-backup-1m-stability.yaml',
                                    DEPLOYMENT_RESTOREBUCKETURL: 'gs://performance-bucket-us-east1/tinghua/1m',
                                    DEPLOYMENT_MAKEBACKUP      : false,
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
