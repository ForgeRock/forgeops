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
            stage("Promote ForgeOps to ${STABLE_BRANCH}") {
                dir ('forgeops-promotion') {
                    // always deep-clone the branch, in order to perform a git merge
                    localGitUtils.deepCloneBranch(scmUtils.getRepoUrl(), env.BRANCH_NAME)
                    sh "git checkout ${commonModule.FORGEOPS_GIT_COMMIT}"

                    promoteDockerImagesToRootLevel()
                    promoteForgeOpsCommitToStable()
                }
            }

            // temporary workaround, to have the promotion in both repos without running PIT tests twice
            stage("Promote Platform Images to ${STABLE_BRANCH}") {
                dir ('platform-images-promotion') {
                    git url: 'ssh://git@stash.forgerock.org:7999/cloud/platform-images.git', branch: STABLE_BRANCH
                    applyForgeOpsPromotionToPlatformImagesRepo()
                }
            }
        }
        return Status.SUCCESS.asOutcome()
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
            "git push origin ${STABLE_BRANCH}"
    )
}

/* Update Skaffold Dockerfiles to use root-level product image names. */
private void useRootLevelImageNamesInDockerfiles() {
    commonModule.dockerImages.each { imageKey, image ->
        String rootImage = "${image.rootLevelBaseImageName}:${image.tag}"
        sh "sed -i 's@FROM gcr.io/forgerock-io.*@FROM ${rootImage}@g' ${image.dockerfilePath}"
    }
}

/* Update Platform Images json to use correct git commit values. */
private void applyForgeOpsPromotionToPlatformImagesRepo() {
    commonModule.platformImages.each { image, rootLevelBaseImageName ->
        def imageFileContent = platformImageUtils.readJSON(file: "${image}.json")
        if (image.equals('lodestar')) {
            [ 'gitCommit', 'platformImagesCommit', 'forgeopsCommit' ].each {
                imageFileContent[ it ] = ""
            }
        } else if (image.equals('forgeops')) {
            [ 'gitCommit', 'platformImagesCommit', 'lodestarCommit' ].each {
                imageFileContent[ it ] = ""
            }
        } else {
            imageFileContent['imageName'] = rootLevelBaseImageName
            imageFileContent['imageTag'] = getImageTagFromDockerfile(image)
            [ 'gitCommit', 'pyforgeCommit', 'lodestarCommit', 'forgeopsCommit', 'commonsVersion', "platformImagesCommit" ].each {
                imageFileContent[ it ] = ""
            }
        }
        platformImageUtils.writeJSON("${image}.json", imageFileContent)
    }
    gitUtils.commitModifiedFiles('Apply ForgeOps promotion to Platform Images repo')
    sh "git push origin ${STABLE_BRANCH}"
}

String getImageTagFromDockerfile(String imageName) {
    // This is brittle, but should be fine for the temporary PIT#2 promotion in both ForgeOps and Platform Images repos.
    // No changes to the ForgeOps Dockerfiles are anticipated on the relevant branches (idcloud 2021.4 to 2021.8).
    if (imageName.equals('ds')) {
        return commonModule.getDockerImage('ds-cts').getTag()
    } else {
        return commonModule.getDockerImage(imageName).getTag()
    }
}

return this
