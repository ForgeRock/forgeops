/*
 * Copyright 2020-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun, Random random) {

    def stageName = 'Basic Perf'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def testName = 'postcommit'
    def randomNumber = random.nextInt(999) + 1000 // 4 digit random number to compute to namespace

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def stagesCloud = [:]
                    stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud(testName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                        def config = [
                            STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
                            EXT_FORGEOPS_PATH    : forgeopsPath,
                            TEST_NAME            : testName,
                            DEPLOYMENT_NAME      : 'small',
                            CLUSTER_DOMAIN       : 'pit-cluster.forgeops.com',
                            CLUSTER_NAMESPACE    : cloud_config.commonConfig()['CLUSTER_NAMESPACE'] + '-' + randomNumber,
                            DO_RECORD_RESULT     : false,
                            PIPELINE_NAME        : 'FORGEOPS_POSTCOMMIT',
                            RUN_INSIDE_CLUSTER   : true,
                        ]

                        withGKEPyrockNoStages(config)
                    }

                    return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                }
            }
        }
    }
}

return this
