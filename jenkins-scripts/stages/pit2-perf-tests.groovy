/*
 * Copyright 2019-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */


import com.forgerock.pipeline.reporting.PipelineRun
import com.forgerock.pipeline.stage.FailureOutcome
import com.forgerock.pipeline.stage.Outcome
import com.forgerock.pipeline.stage.Status

void runStage(PipelineRun pipelineRun) {

    def stageName = 'PIT2 PERF'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('perf-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()

                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def cfg_common = [
                        DO_RECORD_RESULT        : 'True',
                        CLUSTER_NAMESPACE       : 'pyrock',
                        CLUSTER_DOMAIN          : "performance-jenkins.forgeops.com",
                        JENKINS_YAML            : 'jenkins.yaml',
                        STASH_LODESTAR_BRANCH   : commonModule.LODESTAR_GIT_COMMIT,
                        EXT_FORGEOPS_PATH       : forgeopsPath,
                        PIPELINE_NAME           : "ForgeOps-PIT2-promotion",
                    ]

                    def stagesCloud = [:]

                    // perf stack test
                    def subStageName = 'stack'
                    stagesCloud = stageCloudPerf(stagesCloud, subStageName, 'stack')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def cfg = cfg_common.clone()
                        cfg += [
                            USE_SKAFFOLD    : true,
                            TEST_NAME       : "stack",
                        ]

                        withGKEPyrockNoStages(cfg)
                    }

                    // perf am authn rest test
                    subStageName = 'am_authn'
                    stagesCloud = stageCloudPerf(stagesCloud, subStageName, 'authn_rest')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def cfg = cfg_common.clone()
                        cfg += [
                            USE_SKAFFOLD    : true,
                            TEST_NAME       : "authn_rest",
                        ]

                        withGKEPyrockNoStages(cfg)
                    }

                    // perf am access token test
                    subStageName = 'am_access_token'
                    stagesCloud = stageCloudPerf(stagesCloud, subStageName, 'access_token')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def cfg = cfg_common.clone()
                        cfg += [
                            USE_SKAFFOLD    : true,
                            TEST_NAME       : "access_token",
                        ]

                        withGKEPyrockNoStages(cfg)
                    }

                    // IDM CRUD on simple managed users tests
                    subStageName = 'idm_crud'
                    stagesCloud = stageCloudPerf(stagesCloud, subStageName, 'simple_managed_users')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def cfg = cfg_common.clone()
                        cfg += [
                            USE_SKAFFOLD    : true,
                            TEST_NAME       : "simple_managed_users",
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
