/*
 * Copyright 2024 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// create-platform-images-pr.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status

def runStage(PipelineRunLegacyAdapter pipelineRun) {
    pipelineRun.pushStageOutcome('create-platform-images-pr', stageDisplayName: 'Create Platform Images PR') {
        stage('Create Platform Images PR') {
            privateWorkspace {
                def DEFAULT_PLATFORM_IMAGES_TAG = isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME

                def platformImagesRevision = bitbucketUtils.getLatestCommitHash(
                        'cloud',
                        'platform-images',
                        DEFAULT_PLATFORM_IMAGES_TAG)

                def dockerProperties = [
                        'gitCommit'           : commonModule.FORGEOPS_GIT_COMMIT,
                        'platformImagesCommit': platformImagesRevision,
                        'lodestarCommit'      : commonModule.LODESTAR_GIT_COMMIT,
                ]

                return platformImageUtils.createPlatformImagePR('forgeops', env.BRANCH_NAME, dockerProperties)
                        ? Status.SUCCESS.asOutcome()
                        : Status.SKIPPED.asOutcome()
            }
        }
    }
}

return this
