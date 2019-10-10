/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun, String stageName) {

    pipelineRun.pushStageOutcome(commonModule.normalizeStageName(stageName), stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()
                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def cfg = [
                        TESTS_SCOPE          : 'tests/integration',
                        DEPLOYMENT_NAME      : 'ds-shared-repo',
                        CLUSTER_DOMAIN       : 'pit-24-7.forgeops.com',
                        CLUSTER_NAMESPACE    : 'greenfield',
                        REPEAT               : 23,
                        REPEAT_WAIT          : 3600,
                        TIMEOUT              : "24",
                        TIMEOUT_UNIT         : "HOURS",
                        STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
                        SKIP_FORGEOPS        : 'True',
                        EXT_FORGEOPS_PATH    : forgeopsPath
                    ]

                    commonModule.determinePitOutcome("${env.BUILD_URL}/Allure_20Report_20PIT_5fGreenfield") {
                        withGKEPitNoStages(cfg)
                    }
                }
            }
        }
    }
}

return this
