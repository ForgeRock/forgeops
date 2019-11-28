/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun, String stageName) {

    def normStageName = commonModule.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome(normStageName, stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()
                def forgeopsPath = localGitUtils.checkoutForgeops()

                stagesCloud = [:]

                def subStageName = normStageName
                def reportName = "latest-${subStageName}.html"
                stagesCloud = commonModule.addStageCloud(stagesCloud, subStageName, reportName)

                def imageName = 'ds-empty'
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

                dir('lodestar') {
                    commonModule.determineUnitOutcome(stagesCloud[subStageName]) {
                        withGKEPitNoStages(cfg)
                    }
                }

                summaryReportGen.createAndPublishSummaryReport(stagesCloud, stageName, "build&&linux", false, normStageName, "${normStageName}.html")
                return commonModule.determinePitOutcome(stagesCloud, "${env.BUILD_URL}/${normStageName}/")
            }
        }
    }
}

return this
