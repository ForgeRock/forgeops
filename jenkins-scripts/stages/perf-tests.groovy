/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun, String stageName, String testName, String yamlFile) {

    pipelineRun.pushStageOutcome(dashboard_utils.normalizedStageName(stageName), stageDisplayName: stageName) {
        node('perf-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()
                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def cfg = [
                        TEST_NAME            : testName,
                        JENKINS_YAML         : yamlFile,
                        NAMED_REPORT         : true,
                        STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
                        SKIP_FORGEOPS        : 'True',
                        EXT_FORGEOPS_PATH    : forgeopsPath,
                        PIPELINE_NAME        : "ForgeOps-PIT2-promotion"
                    ]

                    testName = testName.replace('_', '_5f')
                    commonModule.determinePyrockOutcome("${env.BUILD_URL}/Pyrock_20Report_20-_20${testName}") {
                        withGKEPyrockNoStages(cfg)
                    }
                }
            }
        }
    }
}

return this
