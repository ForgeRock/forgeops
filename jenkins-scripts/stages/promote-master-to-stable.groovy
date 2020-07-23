/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import groovy.transform.Field

import com.forgerock.pipeline.reporting.PipelineRun
import com.forgerock.pipeline.stage.Status

/** Local branch used for the promotion step. */
@Field String LOCAL_DEV_BRANCH = "promote-forgeops-master-to-stable-${env.BUILD_NUMBER}"

/**
 * Perform the promotion to stable: promote docker images to root level and the relevant commit to 'stable'.
 */
void runStage(PipelineRun pipelineRun) {
    pipelineRun.pushStageOutcome('pit2-promote-to-forgeops-stable', stageDisplayName: 'ForgeOps Stable Promotion') {
        node('build&&linux') {
            stage('Promote to stable') {
                pipelineRun.updateStageStatusAsInProgress()

                localGitUtils.deepCloneBranch(scmUtils.getRepoUrl(), 'master')

                promoteDockerImagesToRootLevel()
                promoteForgeOpsCommitToStable()
                return Status.SUCCESS.asOutcome()
            }
        }
    }
}

private void promoteDockerImagesToRootLevel() {
    sh "git checkout ${commonModule.FORGEOPS_GIT_COMMIT}"
    commonModule.dockerImages.each { imageKey, image ->
        echo "Promoting '${image.baseImageName}:${image.tag}' to root level"
        dockerUtils.copyImage(
                "${image.baseImageName}:${image.tag}",
                "${image.rootLevelBaseImageName}:${image.tag}"
        )
        if (imageKey == 'am') {
            dockerUtils.copyImage(
                    "gcr.io/forgerock-io/am/pit1:${image.tag}",
                    "gcr.io/forgerock-io/am:${image.tag}"
            )
            dockerUtils.copyImage(
                    "gcr.io/forgerock-io/am-config-upgrader/pit1:${image.tag}",
                    "gcr.io/forgerock-io/am-config-upgrader:${image.tag}"
            )
        }
    }
}

private void promoteForgeOpsCommitToStable() {
    echo "Promoting ForgeOps commit ${commonModule.FORGEOPS_SHORT_GIT_COMMIT} to 'stable'"

    sh "git checkout -b ${LOCAL_DEV_BRANCH} ${commonModule.FORGEOPS_GIT_COMMIT}"
    this.useRootLevelImageNamesInDockerfiles()
    gitUtils.commitModifiedFiles('Use stable root-level images in Dockerfiles')

    // temporarily checkout the 'stable' branch, so it can be used for merges
    localGitUtils.deepCloneBranch(scmUtils.getRepoUrl(), 'stable')
    sh "git checkout ${LOCAL_DEV_BRANCH}"

    gitUtils.setupDefaultUser()
    sh commands(
            "git merge --strategy=ours --no-ff stable " +
                    "-m 'Promote commit ${commonModule.FORGEOPS_SHORT_GIT_COMMIT} to stable'",
            'git checkout stable',
            // merge the temporary branch to stable; it contains the master+stable merge commit
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
