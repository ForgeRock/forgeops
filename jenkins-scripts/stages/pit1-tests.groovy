/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun, String stageName, boolean useSkaffold = false) {

    pipelineRun.pushStageOutcome(commonModule.normalizeStageName(stageName), stageDisplayName: stageName) {
        node('google-cloud') {
            dir('forgeops') {
                unstash 'workspace'
            }

            def gitBranch = isPR() ? "origin/pr/${env.CHANGE_ID}" : 'master'
            def gitImageTag = isPR() ? '7.0.0-pr' : '6.5.1'

            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()

                stagesCloud = [:]

                def subStageName = stageName
                def reportName = "latest-${subStageName}.html"
                stagesCloud = commonModule.addStageCloud(stagesCloud, subStageName, reportName)

                def cfg = [
                    TESTS_SCOPE                     : 'tests/platform_deployment',
                    DEPLOYMENT_NAME                 : 'platform-deployment',
                    COMPONENTS_FRCONFIG_GIT_REPO    : "https://stash.forgerock.org/scm/cloud/forgeops.git",
                    COMPONENTS_FRCONFIG_GIT_BRANCH  : gitBranch,
                    COMPONENTS_AMSTER_GITIMAGE_TAG  : gitImageTag,
                    COMPONENTS_AM_GITIMAGE_TAG      : gitImageTag,
                    COMPONENTS_IDM_GITIMAGE_TAG     : gitImageTag,
                    COMPONENTS_IG_GITIMAGE_TAG      : gitImageTag,
                    STASH_LODESTAR_BRANCH           : commonModule.LODESTAR_GIT_COMMIT,
                    SKIP_FORGEOPS                   : 'True',
                    EXT_FORGEOPS_PATH               : "${env.WORKSPACE}/forgeops",
                    USE_SKAFFOLD                    : useSkaffold,
                    REPORT_NAME                     : reportName
                ]

                dir('lodestar') {
                    commonModule.determineUnitOutcome(stagesCloud[subStageName]) {
                        withGKEPitNoStages(cfg)
                    }
                }

                summaryReportGen.createAndPublishSummaryReport(stagesCloud, stageName, "build&&linux", false, stageName, "${stageName.toLowerCase()}.html")
                return commonModule.determinePitOutcome(stagesCloud, "${env.BUILD_URL}/${stageName}/")
            }
        }
    }
}

return this
