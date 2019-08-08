/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun
import com.forgerock.pipeline.stage.FailureOutcome
import com.forgerock.pipeline.stage.Status

void runStage(PipelineRun pipelineRun, String stageName, String scope, String sampleName) {

    pipelineRun.pushStageOutcome(stageName.toLowerCase().replace(' ', '-'), stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()
                def forgeopsPath = localGitUtils.checkoutForgeops()

                dir('lodestar') {
                    def cfg = [
                        TESTS_SCOPE                     : scope,
                        SAMPLE_NAME                     : sampleName,
                        CLUSTER_NAMESPACE               : "upgrade",
                        CLUSTER_DOMAIN                  : "pit-24-7.forgeops.com",
                        COMPONENTS_AMSTER_IMAGE_TAG     : commonModule.UPGRADE_TEST_BASE_AMSTER_VERSION,
                        COMPONENTS_AM_IMAGE_TAG         : commonModule.UPGRADE_TEST_BASE_AM_VERSION,
                        COMPONENTS_IDM_IMAGE_TAG        : commonModule.UPGRADE_TEST_BASE_IDM_VERSION,
                        COMPONENTS_CONFIGSTORE_IMAGE_TAG: commonModule.UPGRADE_TEST_BASE_CONFIGSTORE_VERSION,
                        COMPONENTS_USERSTORE_IMAGE_TAG  : commonModule.UPGRADE_TEST_BASE_USERSTORE_VERSION,
                        COMPONENTS_AM_CATALINAOPTS      : "-server -Dorg.forgerock.donotupgrade=true -Dcom.sun.identity.configuration.directory=/home/forgerock/openam -Dcom.iplanet.services.stats.state=off",
                        STASH_LODESTAR_BRANCH           : commonModule.LODESTAR_GIT_COMMIT,
                        SKIP_FORGEOPS                   : 'True',
                        EXT_FORGEOPS_PATH               : forgeopsPath
                    ]

                    determinePitOutcome() {
                        withGKEPitNoStages(cfg)
                    }
                }
            }
        }
    }
}

def determinePitOutcome(Closure process) {
    try {
        process()
        return Status.SUCCESS.asOutcome()
    } catch (Exception e) {
        return new FailureOutcome(e)
    }
}

return this
