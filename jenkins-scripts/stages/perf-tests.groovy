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

    pipelineRun.pushStageOutcome(dashboard_utils.normalizeStageName(stageName), stageDisplayName: stageName) {
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
                    stagesCloud = stageCloudPerf(stagesCloud, "stack", helm_report_loc, "stack")

                    dashboard_utils.determineUnitOutcome(stagesCloud['stack']) {
                        def cfg = cfg_common.clone()
                        cfg += [
                            USE_SKAFFOLD: false,
                            TEST_NAME   : "stack",
                        ]

                        withGKEPyrockNoStages(cfg)
                    }

                    // perf authn rest test
                    stagesCloud = stageCloudPerf(stagesCloud, "am_authn", helm_report_loc, "authn_rest")

                    dashboard_utils.determineUnitOutcome(stagesCloud['am_authn']) {
                        def cfg = cfg_common.clone()
                        cfg += [
                            USE_SKAFFOLD: false,
                            TEST_NAME   : "authn_rest",
                        ]

                        withGKEPyrockNoStages(cfg)
                    }

                    // CRUD on simple managed users tests
                    stagesCloud = stageCloudPerf(stagesCloud, "idm_crud", helm_report_loc, "simple_managed_users")

                    dashboard_utils.determineUnitOutcome(stagesCloud['idm_crud']) {
                        def cfg = cfg_common.clone()
                        cfg += [
                            USE_SKAFFOLD: false,
                            TEST_NAME   : "simple_managed_users",
                        ]

                        withGKEPyrockNoStages(cfg)
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