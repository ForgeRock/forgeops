/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// promote-to-stable-branch.groovy

import groovy.transform.Field

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status

/** Local branch used for the promotion step. */
@Field String LOCAL_DEV_BRANCH = "promote-forgeops-${env.BRANCH_NAME}-to-stable-branch-${env.BUILD_NUMBER}"

/** Corresponding Stable branch for this ForgeOps branch. */
@Field String STABLE_BRANCH = env.BRANCH_NAME.equals('master') ? 'stable' : "${env.BRANCH_NAME}-stable"

/**
 * Perform the promotion to stable: promote docker images to root level and the relevant commit to 'stable'.
 */
void runStage(PipelineRunLegacyAdapter pipelineRun) {
    pipelineRun.pushStageOutcome('pit2-promote-to-forgeops-stable', stageDisplayName: 'ForgeOps Stable Promotion') {
        node('build&&linux') {
            stage("Promote to ${STABLE_BRANCH}") {
                // always deep-clone the branch, in order to perform a git merge
                localGitUtils.deepCloneBranch(scmUtils.getRepoUrl(), env.BRANCH_NAME)
                sh "git checkout ${commonModule.FORGEOPS_GIT_COMMIT}"

                promoteDockerImagesToRootLevel()
                promoteForgeOpsCommitToStable()
                return Status.SUCCESS.asOutcome()
            }
        }
    }
}

private void promoteDockerImagesToRootLevel() {
    commonModule.dockerImages.each { imageKey, image ->
        echo "Promoting '${image.baseImageName}:${image.tag}' to root level"
        dockerUtils.copyImage(
                "${image.baseImageName}:${image.tag}",
                "${image.rootLevelBaseImageName}:${image.tag}"
        )
        // Promote 'am-config-upgrader' image in addition to 'am-base'
        if (imageKey == 'am') {
            dockerUtils.copyImage(
                    "gcr.io/forgerock-io/am-config-upgrader/pit1:${image.tag}",
                    "gcr.io/forgerock-io/am-config-upgrader:${image.tag}"
            )
        }
        // Promote 'ds-empty' image in addition to 'ds' one
        if (imageKey == 'ds-idrepo') {
            dockerUtils.copyImage(
                    "gcr.io/forgerock-io/ds-empty/pit1:${image.tag}",
                    "gcr.io/forgerock-io/ds-empty:${image.tag}"
            )
        }
    }
}

private void promoteForgeOpsCommitToStable() {
    echo "Promoting ForgeOps commit ${commonModule.FORGEOPS_SHORT_GIT_COMMIT} to ${STABLE_BRANCH}"

    sh "git checkout -b ${LOCAL_DEV_BRANCH} ${commonModule.FORGEOPS_GIT_COMMIT}"
    this.useRootLevelImageNamesInDockerfiles()
    gitUtils.commitModifiedFiles('Use stable root-level images in Dockerfiles')

    localGitUtils.deepCloneBranch(scmUtils.getRepoUrl(), STABLE_BRANCH)
    sh "git checkout ${LOCAL_DEV_BRANCH}"

    gitUtils.setupDefaultUser()
    sh commands(
            "git merge --strategy=ours --no-ff ${STABLE_BRANCH} " +
                    "-m 'Promote commit ${commonModule.FORGEOPS_SHORT_GIT_COMMIT} to ${STABLE_BRANCH}'",
            "git checkout ${STABLE_BRANCH}",
            // merge the temporary branch to stable; it contains the source+target branch merge commit
            "git merge --ff-only ${LOCAL_DEV_BRANCH}",
            'git push'
    )
}

/* Update Skaffold Dockerfiles to use root-level product image names. */
private void useRootLevelImageNamesInDockerfiles() {
    commonModule.dockerImages.each { imageKey, image ->
        String rootImage = "${image.rootLevelBaseImageName}:${image.tag}"
        sh "sed -i 's@FROM gcr.io/forgerock-io.*@FROM ${rootImage}@g' ${image.dockerfilePath}"
    }
}

return this
