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
    def config_common = [
            STASH_PLATFORM_IMAGES_BRANCH    : commonModule.platformImagesRevision,
            STASH_FORGEOPS_BRANCH           : commonModule.FORGEOPS_GIT_COMMIT,
            STASH_LODESTAR_BRANCH           : commonModule.lodestarRevision,
            CLUSTER_DOMAIN                  : 'pit2-perf.forgeops.com',
            PIPELINE_NAME                   : "ForgeOps-PIT2-promotion",
            CHECK_REGRESSION                : true,
            MAX_VARIATION                   : '0.10',
    ]

    def parentStageName = 'PIT2 Perf'
    def tags = ['PIT2', 'performance']
    def parallelTestsMap = [:]

    // perf platform test
    if (params.PIT2_Perf_platform) {
        parallelTestsMap.put("${parentStageName} platform",
                {
                    runPyrock(pipelineRun, "${parentStageName} platform", tags, config_common +
                            [TEST_NAME   : 'platform',
                             BASELINE_RPS: '[1983,1722,1136,360]']
                    )
                }
        )
    }

    // perf am authn rest test
    if (params.PIT2_Perf_am_authn) {
        parallelTestsMap.put("${parentStageName} am_authn",
                {
                    runPyrock(pipelineRun, "${parentStageName} am_authn", tags, config_common +
                            [TEST_NAME   : 'authn_rest',
                             BASELINE_RPS: '2550']
                    )
                }
        )
    }

    // perf am access token test
    if (params.PIT2_Perf_am_access_token) {
        parallelTestsMap.put("${parentStageName} am_access_token",
                {
                    runPyrock(pipelineRun, "${parentStageName} am_access_token", tags, config_common +
                            [TEST_NAME   : 'access_token',
                             BASELINE_RPS: '[2733,2453]']
                    )
                }
        )
    }

    // perf IDM CRUD on simple managed users tests
    if (params.PIT2_Perf_idm_crud) {
        parallelTestsMap.put("${parentStageName} idm_crud",
                {
                    runPyrock(pipelineRun, "${parentStageName} idm_crud", tags, config_common +
                            [TEST_NAME   : 'simple_managed_users',
                             BASELINE_RPS: '[5688,0,0,0,1336,1177,1274,955]']
                    )
                }
        )
    }

    parallel parallelTestsMap
}

def runPyrock(PipelineRunLegacyAdapter pipelineRun, String stageName, ArrayList tags, Map config) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome([tags: tags, stageDisplayName: stageName], normalizedStageName) {
        node('perf-cloud') {
            stage(stageName) {
                dir('lodestar') {
                    def stagesCloud = [:]
                    stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud(config.TEST_NAME)

                    dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                        withGKEPyrockNoStages(config)
                    }

                    return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                }
            }
        }
    }
}

return this
