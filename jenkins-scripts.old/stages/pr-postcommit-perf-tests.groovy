/*
 * Copyright 2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun, Random random) {

    def stageName = "PERF"
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def testName = 'postcommit'
    def randomNumber = random.nextInt(999) + 1000 // 4 digit random number to compute to namespace

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()

                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def stagesCloud = [:]

                    def subStageName = isPR() ? 'pr' : 'postcommit'
                    stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud(testName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def config = [
                            STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
                            EXT_FORGEOPS_PATH    : forgeopsPath,
                            TEST_NAME            : testName,
                            DEPLOYMENT_NAME      : 'small',
                            CLUSTER_DOMAIN       : 'pit-cluster.forgeops.com',
                            CLUSTER_NAMESPACE    : cloud_config.commonConfig()['CLUSTER_NAMESPACE'] + '-' + randomNumber,
                            DO_RECORD_RESULT     : false,
                            PIPELINE_NAME        : 'FORGEOPS_POSTCOMMIT',
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
