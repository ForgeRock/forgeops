/*
 * Copyright 2021-2024 Ping Identity Corporation. All Rights Reserved
 * 
 * This code is to be used exclusively in connection with Ping Identity 
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a 
 * binding license agreement with Ping Identity Corporation.
 */

// create-platform-images-pr.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status

/** Open a pull request against the Platform-Images repo, containing latest ForgeOps commit */
void runStage(PipelineRunLegacyAdapter pipelineRun) {
    stage ('Create Platform Images PR') {
        pipelineRun.pushStageOutcome('create-platform-images-pr', stageDisplayName: 'Create Platform-Images PR') {
            privateWorkspace {
                def dockerProperties = [
                        'gitCommit':            commonModule.GIT_COMMIT,
                        'platformImagesCommit': commonModule.platformImagesRevision,
                        'lodestarCommit':       commonModule.lodestarRevision,
                ]

                return platformImageUtils.createPlatformImagePR('forgeops', env.BRANCH_NAME, dockerProperties)
                        ? Status.SUCCESS.asOutcome()
                        : Status.SKIPPED.asOutcome()
            }
        }
    }
}

return this
