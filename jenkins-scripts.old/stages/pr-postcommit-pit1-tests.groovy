/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// pr-postcommit-pit1-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun, Random random) {

    def stageName = 'PIT1'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def randomNumber = random.nextInt(999) + 1000 // 4 digit random number to compute to namespace

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def stagesCloud = [:]
                    stagesCloud[normalizedStageName] = dashboard_utils.spyglaasStageCloud(normalizedStageName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                        def config = [
                            TESTS_SCOPE             : 'tests/pit1',
                            STASH_LODESTAR_BRANCH   : commonModule.LODESTAR_GIT_COMMIT,
                            EXT_FORGEOPS_PATH       : forgeopsPath,
                            CLUSTER_NAMESPACE       : cloud_config.commonConfig()['CLUSTER_NAMESPACE'] + '-' + randomNumber,
                            REPORT_NAME_PREFIX      : normalizedStageName,
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
