/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun
import com.forgerock.pipeline.stage.Status

/**
 * Perform the promotion to stable: promote docker images to root level and the relevant commit to 'stable'.
 */
void runStage(PipelineRun pipelineRun) {
    pipelineRun.pushStageOutcome('promote-to-forgeops-stable', stageDisplayName: 'ForgeOps Stable Promotion') {
        node('build&&linux') {
            stage('Promote to stable') {
                pipelineRun.updateStageStatusAsInProgress()
                promoteDockerImagesToRootLevel()
                promoteForgeOpsCommitToStable()
                return Status.SUCCESS.asOutcome()
            }
        }
    }
}

private void promoteDockerImagesToRootLevel() {
    commonModule.getHelmCharts().each { helmChart ->
        echo "Promoting '${helmChart.currentImageName}:${helmChart.currentTag}' to root level"
        dockerUtils.copyImage(
                "${helmChart.currentImageName}:${helmChart.currentTag}",
                "${helmChart.rootLevelImageName}:${helmChart.currentTag}"
        )
    }
}

private void promoteForgeOpsCommitToStable() {
    echo "Promoting ForgeOps commit ${commonModule.FORGEOPS_SHORT_GIT_COMMIT} to 'stable'"
    def repoUrl = scmUtils.getRepoUrl()
    def localDevBranch = "promote-forgeops-master-to-stable-${env.BUILD_NUMBER}"

    localGitUtils.deepCloneBranch(repoUrl, 'master')
    sh "git checkout -b ${localDevBranch} ${commonModule.FORGEOPS_GIT_COMMIT}"
    this.useRootLevelImageNamesInHelmCharts()
    this.useRootLevelImageNamesInDockerfiles()
    gitUtils.setupDefaultUser()
    sh 'git commit --all --message="Promote stable root-level images to Helm charts and Dockerfiles"'

    localGitUtils.deepCloneBranch(repoUrl, 'stable')

    sh commands(
            "git merge -Xtheirs --no-ff ${localDevBranch} -m " +
                    "'Promote commit ${commonModule.FORGEOPS_SHORT_GIT_COMMIT} to stable'",
            'git push'
    )
}

/* Update Helm charts to use root-level product image names.
 * Master branch uses the '/pit1' image name appendix; this can be removed once the image is promoted to the root level.
 */
private void useRootLevelImageNamesInHelmCharts() {
    commonModule.getHelmCharts().each { helmChart ->
        sh "sed -i 's@${helmChart.currentImageName}@${helmChart.rootLevelImageName}@g' ${helmChart.filePath}"
    }
}

/* Update Skaffold Dockerfiles to use root-level product image names. */
private void useRootLevelImageNamesInDockerfiles() {
    commonModule.getDockerfiles().each { dockerfile ->
        sh "sed -i 's@FROM gcr.io/forgerock-io.*@FROM ${dockerfile.fullImageName}@g' ${dockerfile.filePath}"
    }
}

return this