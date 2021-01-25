/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun, Random random) {

    def stageName = 'PIT1'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def randomNumber = random.nextInt(999) + 1000 // 4 digit random number to compute to namespace

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                def forgeopsPath = localGitUtils.checkoutForgeops()

                def gitBranch = isPR() ? "origin/pr/${env.CHANGE_ID}" : 'master'

                dir('lodestar') {
                    def stagesCloud = [:]

                    def subStageName = isPR() ? 'pr' : 'postcommit'
                    stagesCloud[subStageName] = dashboard_utils.spyglaasStageCloud(subStageName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def config = [
                            TESTS_SCOPE             : 'tests/pit1',
                            STASH_LODESTAR_BRANCH   : commonModule.LODESTAR_GIT_COMMIT,
                            EXT_FORGEOPS_PATH       : forgeopsPath,
                            CLUSTER_NAMESPACE       : cloud_config.commonConfig()['CLUSTER_NAMESPACE'] + '-' + randomNumber,
                            REPORT_NAME_PREFIX      : subStageName,
                        ]

                        withGKESpyglaasNoStages(config)
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
