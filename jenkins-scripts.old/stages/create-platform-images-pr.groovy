/*
 * Copyright 2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// create-platform-images-pr.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status

/** Open a pull request against the Platform-Images repo, containing latest ForgeOps commit */
void runStage(PipelineRunLegacyAdapter pipelineRun) {
    pipelineRun.pushStageOutcome('create-platform-images-pr', stageDisplayName: 'Create Platform-Images PR') {
        node('google-cloud') {
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
