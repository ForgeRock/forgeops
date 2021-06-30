/*
 * Copyright 2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// pit2-idcloud-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun) {

    def stageName = 'PIT2 IDCloud'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome([tags : ['PIT2'], stageDisplayName : stageName], normalizedStageName) {
        // TODO: To update to use 'pit2-idcloud' once RELENG-1165 is done
        node('pit2-upgrade') {
            stage(stageName) {
                dir('lodestar') {
                    def stagesCloud = [:]
                    stagesCloud[normalizedStageName] = dashboard_utils.spyglaasStageCloud(normalizedStageName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                        def config = [
                            TESTS_SCOPE                     : 'tests/pit1',
                            STASH_PLATFORM_IMAGES_BRANCH    : commonModule.platformImagesRevision,
                            STASH_FORGEOPS_BRANCH           : commonModule.FORGEOPS_GIT_COMMIT,
                            STASH_LODESTAR_BRANCH           : commonModule.lodestarRevision,
                            REPORT_NAME_PREFIX              : normalizedStageName,
                            TENANT                          : 'openam-pitperf-tests',
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