/*
 * Copyright 2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun) {
    def stageName = "PERF-PR-Postcommit"
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()

                dir('forgeops') {
                    unstash 'workspace'
                }

                dir('lodestar') {
                    def stagesCloud = [:]
                    subStageName = 'skaffold'
                    stagesCloud[subStageName] = dashboard_utils.stageCloud(normalizedStageName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def namespace = cloud_utils.transformNamespace("jenkins-${env.JOB_NAME}-${env.BUILD_NUMBER}")
                        withGKEPyrockNoStages([
                            STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
                            SKIP_FORGEOPS        : 'True',
                            EXT_FORGEOPS_PATH    : "${env.WORKSPACE}/forgeops",
                            TEST_NAME            : 'postcommit',
                            CLUSTER_DOMAIN       : "pit-cluster.forgeops.com",
                            CLUSTER_NAMESPACE    : namespace + (new Random().nextInt(10**4)),
                            PIPELINE_NAME        : "FORGEOPS_POSTCOMMIT",
                            USE_SKAFFOLD         : true,
                        ])
                    }

                    // Summary and combined report generation
                    summaryReportGen.createAndPublishSummaryReport(
                        stagesCloud, stageName, 'build&&linux', false, stageName, "${normalizedStageName}.html")
                    return dashboard_utils.determineLodestarOutcome(stagesCloud,
                                                                    "${env.BUILD_URL}/${normalizedStageName}/")
                }
            }
        }
    }
}

return this
