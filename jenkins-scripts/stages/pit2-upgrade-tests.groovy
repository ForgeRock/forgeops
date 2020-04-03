/*
 * Copyright 2019-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun) {

    def stageName = 'PIT2 Upgrade'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()

                dir('lodestar') {
                    def stagesCloud = [:]

                    // Upgrade tests
                    def subStageName = 'upgrade'
                    def reportName = "latest-${subStageName}.html"
                    stagesCloud[subStageName] = dashboard_utils.stageCloud(reportName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def cfg = [
                            USE_SKAFFOLD                            : true,
                            TESTS_SCOPE                             : 'test/pit2/upgrade',
                            CLUSTER_DOMAIN                          : 'pit-24-7.forgeops.com',
                            CLUSTER_NAMESPACE                       : subStageName,
                            COMPONENTS_AM_IMAGE_UPGRADE_TAG         : getHelmChart('am').currentTag,
                            COMPONENTS_IDM_IMAGE_UPGRADE_TAG        : getHelmChart('idm').currentTag,
                            COMPONENTS_IG_IMAGE_UPGRADE_TAG         : getHelmChart('ig').currentTag,
                            COMPONENTS_DSIDREPO_IMAGE_UPGRADE_TAG   : getHelmChart('ds-empty').currentTag,
                            STASH_LODESTAR_BRANCH                   : commonModule.LODESTAR_GIT_COMMIT,
                            STASH_FORGEOPS_BRANCH                   : 'fraas-production',
                            REPORT_NAME                             : reportName,
                        ]

                        withGKESpyglaasNoStages(cfg)
                    }

                    summaryReportGen.createAndPublishSummaryReport(stagesCloud, stageName, 'build&&linux', false, normalizedStageName, "${normalizedStageName}.html")
                    return dashboard_utils.determineLodestarOutcome(stagesCloud, "${env.BUILD_URL}/${normalizedStageName}/")
                }
            }
        }
    }
}

return this
