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

                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def stagesCloud = [:]
                    subStageName = 'skaffold'
                    stagesCloud = stageCloudPerf(stagesCloud, subStageName, 'postcommit')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def cfg = [
                            STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
                            EXT_FORGEOPS_PATH    : forgeopsPath,
                            TEST_NAME            : 'postcommit',
                            CLUSTER_DOMAIN       : "pit-cluster.forgeops.com",
                            JENKINS_YAML         : 'lodestar-postcommit.yaml',
                            CLUSTER_NAMESPACE    : cloud_config.cloudConfig()['CLUSTER_NAMESPACE'],
                            PIPELINE_NAME        : "FORGEOPS_POSTCOMMIT",
                            USE_SKAFFOLD         : true,
                        ]

                        withGKEPyrockNoStages(cfg)
                    }

                    // Summary and combined report generation
                    summaryReportGen.createAndPublishSummaryReport(stagesCloud, stageName, 'build&&linux', false, normalizedStageName, "${normalizedStageName}.html")
                    return dashboard_utils.determineLodestarOutcome(stagesCloud, "${env.BUILD_URL}/${normalizedStageName}/")
                }
            }
        }
    }
}

def stageCloudPerf(HashMap stagesCloud, String subStageName, String testName) {
    stagesCloud[subStageName] = [
        'numFailedTests': 0,
        'testsDuration' : -1,
        'reportUrl'     : "${env.BUILD_URL}/artifact/results/pyrock/${testName}/global.html",
        'exception'     : null
    ]
    return stagesCloud
}

return this
