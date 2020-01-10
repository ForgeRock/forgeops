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

void runStage(PipelineRun pipelineRun, String stageName, String yamlFile, String doRecordResult, String clusterNamespace) {

    pipelineRun.pushStageOutcome(dashboard_utils.normalizedStageName(stageName), stageDisplayName: stageName) {
        node('perf-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()

                dir('lodestar') {
                    def helm_report_loc = "helm"
                    def skaffold_report_loc = "skaffold"

                    def cfg_common = [
                            DO_RECORD_RESULT     : doRecordResult,
                            CLUSTER_NAMESPACE    : clusterNamespace,
                            CLUSTER_DOMAIN       : "performance-jenkins.forgeops.com",
                            JENKINS_YAML         : yamlFile,
                            STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
                            SKIP_FORGEOPS        : 'True',
                            EXT_FORGEOPS_PATH    : "${env.WORKSPACE}/forgeops",
                            PIPELINE_NAME        : "ForgeOps-PIT2-promotion"
                    ]

                    def stagesCloud = [:]

                    // perf stack test
                    stagesCloud = stageCloudPerf(stagesCloud, "stack", skaffold_report_loc, "stack")
                    def cfg_stack = cfg_common.clone()
                    cfg_stack += [
                            USE_SKAFFOLD: false,
                            TEST_NAME   : "stack",
                    ]

                    dashboard_utils.determineUnitOutcome(stagesCloud['stack']) {
                        withGKEPyrockNoStages(cfg_stack)
                    }

                    // perf authn rest test
                    def cfg_authn = cfg_common.clone()
                    stagesCloud = stageCloudPerf(stagesCloud, "am_authn", skaffold_report_loc, "authn_rest")
                    cfg_authn += [
                            USE_SKAFFOLD: false,
                            TEST_NAME   : "authn_rest",
                    ]

                    dashboard_utils.determineUnitOutcome(stagesCloud['am_authn']) {
                        withGKEPyrockNoStages(cfg_authn)
                    }

                    // CRUD on simple managed users tests
                    def cfg_idm_crud = cfg_common.clone()
                    stagesCloud = stageCloudPerf(stagesCloud, "idm_crud", helm_report_loc, "simple_managed_users")
                    cfg_idm_crud += [
                            USE_SKAFFOLD: false,
                            TEST_NAME   : "simple_managed_users",
                    ]

                    dashboard_utils.determineUnitOutcome(stagesCloud['idm_crud']) {
                        withGKEPyrockNoStages(cfg_idm_crud)
                    }

                    // Summary and combined report generation
                    summaryReportGen.createAndPublishSummaryReport(stagesCloud, "PERF-TESTS", "build && linux", false, "PERF", "perf.html")
                    return dashboard_utils.determineLodestarOutcome(stagesCloud, "${env.BUILD_URL}/PERF/")
                }
            }
        }
    }
}

def stageCloudPerf(HashMap stagesCloud, String subStageName, String reportLoc, String testName) {
    stagesCloud[subStageName] = [
            'numFailedTests': 0,
            'testsDuration' : -1,
            'reportUrl'     : "${env.BUILD_URL}/artifact/results/pyrock/${testName}-${reportLoc}/global.html",
            'exception'     : null
    ]
    return stagesCloud
}

return this