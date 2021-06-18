/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// pit2-greenfield-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun) {

    def stageName = 'PIT2 Greenfield'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome([tags : ['PIT2'], stageDisplayName : stageName], normalizedStageName) {
        node('pit2-greenfield') {
            stage(stageName) {
                dir('lodestar') {
                    def stagesCloud = [:]
                    stagesCloud[normalizedStageName] = dashboard_utils.spyglaasStageCloud(normalizedStageName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                        def config = [
                            TESTS_SCOPE                     : 'tests/pit1',
                            CLUSTER_DOMAIN                  : 'pit2.forgeops.com',
                            CLUSTER_NAMESPACE               : 'greenfield',
                            CLUSTER_CRASHER                 : 'True',
                            MAX_DURATION                    : params.PIT2_Greenfield.toInteger(),
                            WAIT_LOOP                       : 600,
                            TIMEOUT                         : '14',
                            TIMEOUT_UNIT                    : 'HOURS',
                            STASH_LODESTAR_BRANCH           : commonModule.LODESTAR_GIT_COMMIT,
                            STASH_FORGEOPS_BRANCH           : commonModule.FORGEOPS_GIT_COMMIT,
                            REPORT_NAME_PREFIX              : normalizedStageName,
                        ]

                        withGKESpyglaasNoStages(config)
                    }

                    return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                }
            }
        }
    }
}

return this
