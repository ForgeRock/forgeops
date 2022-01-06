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
        def prBranchName = "increment-platform-images-version-to-${commonModule.FORGEOPS_SHORT_GIT_COMMIT}"
        def targetPlatformImagesBranch = env.BRANCH_NAME // promote product branches to identically-named branch in ForgeOps

        node('build&&linux') {
            git branch: targetPlatformImagesBranch, url: 'ssh://git@stash.forgerock.org:7999/~rockbot/platform-images.git'
            sh "git checkout -b ${prBranchName}"
            gitUtils.setupDefaultUser()

            def forgeOpsProperties = [
                    'gitCommit':    commonModule.FORGEOPS_GIT_COMMIT
            ]

            platformImageUtils.createPlatformImagePR('forgeops', targetPlatformImagesBranch, forgeOpsProperties)

            return Status.SUCCESS.asOutcome()
        }
    }
}

return this
