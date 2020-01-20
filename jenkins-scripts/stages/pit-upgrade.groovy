/*
 * Copyright 2019-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun) {

    def stageName = 'PIT Upgrade'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()

                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def stagesCloud = [:]

                    // Upgrade tests
                    def subStageName = 'upgrade'
                    def reportName = "latest-${subStageName}.html"
                    stagesCloud[subStageName] = dashboard_utils.stageCloud(reportName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def cfg = [
                            TESTS_SCOPE                     : 'tests/upgrade',
                            DEPLOYMENT_NAME                 : 'platform-deployment',
                            CLUSTER_DOMAIN                  : 'pit-24-7.forgeops.com',
                            CLUSTER_NAMESPACE               : subStageName,
                            COMPONENTS_FRCONFIG_GIT_REPO    : "https://stash.forgerock.org/scm/cloud/forgeops.git",
                            COMPONENTS_FRCONFIG_GIT_BRANCH  : commonModule.FORGEOPS_GIT_COMMIT,
                            COMPONENTS_AMSTER_IMAGE_TAG     : commonModule.UPGRADE_TEST_BASE_AMSTER_VERSION,
                            COMPONENTS_AM_IMAGE_TAG         : commonModule.UPGRADE_TEST_BASE_AM_VERSION,
                            COMPONENTS_IDM_IMAGE_TAG        : commonModule.UPGRADE_TEST_BASE_IDM_VERSION,
                            COMPONENTS_DS_IMAGE_TAG         : commonModule.UPGRADE_TEST_BASE_DSEMPTY_VERSION,
                            STASH_LODESTAR_BRANCH           : commonModule.LODESTAR_GIT_COMMIT,
                            EXT_FORGEOPS_BRANCH             : 'fraas-production',
                            EXT_FORGEOPS_UPGRADE_BRANCH     : commonModule.FORGEOPS_GIT_COMMIT,
                            REPORT_NAME                     : reportName
                        ]

                        withGKEPitNoStages(cfg)
                    }

                    summaryReportGen.createAndPublishSummaryReport(stagesCloud, stageName, "build&&linux", false, normalizedStageName, "${normalizedStageName}.html")
                    return dashboard_utils.determineLodestarOutcome(stagesCloud, "${env.BUILD_URL}/${normalizedStageName}/")
                }
            }
        }
    }
}

return this
