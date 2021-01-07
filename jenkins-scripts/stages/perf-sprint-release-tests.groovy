/*
 * Copyright 2020 ForgeRock AS. All Rights Reserved
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

    def stageName = 'PERF Sprint Release'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()
                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def config_common = [
                        STASH_LODESTAR_BRANCH   : commonModule.LODESTAR_GIT_COMMIT,
                        EXT_FORGEOPS_PATH       : forgeopsPath,
                        PIPELINE_NAME           : 'ForgeOps - Perf-Sprint-Release',
                        CHECK_REGRESSION        : true,
                        MAX_VARIATION           : '0.10',
                        CLUSTER_DOMAIN          : 'perf-sprint-release.forgeops.com',
                        TIMEOUT                 : '12',
                        TIMEOUT_UNIT            : 'HOURS',
                    ]

                    def stagesCloud = [:]

                    // perf am authn rest test
                    def subStageName = 'am_authn_long'
                    stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('authn_rest')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def config = config_common.clone()
                        config += [
                            TEST_NAME                  : "authn_rest",
                            DEPLOYMENT_RESTOREBUCKETURL: 'gs://performance-bucket-us-east1/nemanja/3ds-10M-bis',
                            DEPLOYMENT_MAKEBACKUP      : false,
                            SET_OPTIONS                : "--set phases['scenario'].duration=6 --set phases['scenario'].duration-unit=h --set components.servers['ds-idrepo'].num-entries=10000000",
                        ]

                        withGKEPyrockNoStages(config)
                    }

                    // perf am access token test
                    subStageName = 'am_access_token_long'
                    stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('access_token')

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def config = config_common.clone()
                        config += [
                            TEST_NAME                  : "access_token",
                            DEPLOYMENT_RESTOREBUCKETURL: 'gs://performance-bucket-us-east1/nemanja/3ds-10M-bis',
                            DEPLOYMENT_MAKEBACKUP      : false,
                            SET_OPTIONS                : "--set phases['scenario'].duration=6 --set phases['scenario'].duration-unit=h --set components.servers['ds-idrepo'].num-entries=10000000",
                        ]

                        withGKEPyrockNoStages(config)
                    }

                    //// perf platform test
                    //subStageName = 'platform_long'
                    //stagesCloud[subStageName] = dashboard_utils.pyrockStageCloud('platform')
//
                    //dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                    //    def config = config_common.clone()
                    //    config += [
                    //        TEST_NAME       : "platform",
                    //        BASELINE_RPS    : '[1983,1722,1136,360]',
                    //        SET_OPTIONS     : "--set phases['scenario'].duration=6 --set phases['scenario'].duration-unit=h",
                    //    ]
//
                    //    withGKEPyrockNoStages(config)
                    //}

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
