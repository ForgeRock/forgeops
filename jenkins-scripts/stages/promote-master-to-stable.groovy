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
                sh "git checkout -b ${LOCAL_DEV_BRANCH} ${commonModule.FORGEOPS_GIT_COMMIT}"

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
    }
}

private void promoteForgeOpsCommitToStable() {
    echo "Promoting ForgeOps commit ${commonModule.FORGEOPS_SHORT_GIT_COMMIT} to 'stable'"

    this.useRootLevelImageNamesInDockerfiles()
    gitUtils.commitModifiedFiles('Use stable root-level images in Dockerfiles')

    localGitUtils.deepCloneBranch(scmUtils.getRepoUrl(), 'stable')

    sh commands(
            "git merge -Xtheirs --no-ff ${LOCAL_DEV_BRANCH} -m " +
                    "'Promote commit ${commonModule.FORGEOPS_SHORT_GIT_COMMIT} to stable'",
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