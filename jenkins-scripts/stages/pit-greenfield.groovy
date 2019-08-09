/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import java.time.Instant
import com.forgerock.pipeline.reporting.PipelineRun

def getTimeDiff(start, end) {
    return end - start
}

def getEpochTime() {
    return Instant.now().epochSecond
}

void runStage(PipelineRun pipelineRun, String stageName) {

    pipelineRun.pushStageOutcome(commonModule.normalizeStageName(stageName), stageDisplayName: stageName) {
        def cfg = [
            TESTS_SCOPE          : 'tests/integration',
            SAMPLE_NAME          : 'ds-shared-repo',
            CLUSTER_DOMAIN       : 'pit-24-7.forgeops.com',
            SKIP_CLEANUP         : 'True',
            RUN_NAME             : 'Initial',
            CLUSTER_NAMESPACE    : 'greenfield',
            STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
            SKIP_FORGEOPS        : 'True',
        ]

        stage(stageName) {
            pipelineRun.updateStageStatusAsInProgress()
            // Initial run with deployment
            def start = getEpochTime()

            runTest(cfg)

            def end = getEpochTime()
            sleep(3600 - getTimeDiff(start, end))

            /* This pipeline is run once per day; the greenfield tests are run once per hour. 22 runs fills the day.
             * First run already done in first stage with deployment, last is done with cleanup in separate stage. */
            def runs = 22
            cfg.SKIP_DEPLOY = 'True'

            runs.times {
                start = getEpochTime()
                runTest(cfg)
                end = getEpochTime()
                sleep(3600 - getTimeDiff(start, end))
            }

            // Last run with cleanup
            cfg.SKIP_CLEANUP = 'False'
            cfg.RUN_NAME = 'Last'

            runTest(cfg)
        }
    }
}

private void runTest(cfg) {
    node('google-cloud') {
        def forgeopsPath = localGitUtils.checkoutForgeops()

        dir('lodestar') {
            cfg.EXT_FORGEOPS_PATH = forgeopsPath
            commonModule.determinePitOutcome("${env.BUILD_URL}") {
                withGKEPitNoStages(cfg)
            }
        }
    }
}

return this
