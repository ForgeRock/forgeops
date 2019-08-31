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
    commonModule.HELM_CHARTS.each { product, helmChart ->
        echo "Promoting ${product} docker image ${helmChart.currentTag} to root level"
        dockerUtils.copyImage(
                "${helmChart.currentImageName}:${helmChart.currentTag}",
                "${helmChart.rootLevelImageName}:${helmChart.currentTag}"
        )
    }
}

private void promoteForgeOpsCommitToStable() {
    echo "Promoting ForgeOps commit ${commonModule.FORGEOPS_SHORT_GIT_COMMIT} to 'stable'"
    def repoUrl = scmUtils.getRepoUrl()
    def localDevBranch = 'use-root-level-image-names-in-stable-helm-charts'

    localGitUtils.deepCloneBranch(repoUrl, 'master')
    sh "git checkout -b ${localDevBranch} ${commonModule.FORGEOPS_GIT_COMMIT}"
    this.useRootLevelImageNamesInHelmCharts()
    gitUtils.setupDefaultUser()
    sh 'git commit --all -m "Use root-level image names in stable helm charts"'

    localGitUtils.deepCloneBranch(repoUrl, 'stable')
    sh commands(
            "git merge -Xtheirs --no-ff ${localDevBranch} -m " +
                    "'Promote commit ${commonModule.FORGEOPS_SHORT_GIT_COMMIT} to stable'",
            'git push'
    )
}

/* Update the Helm charts to use the root-level product container names.
 * Master branch uses the '/pit1' image name appendix; this can be removed once the image is promoted to the root level.
 */
private void useRootLevelImageNamesInHelmCharts() {
    commonModule.HELM_CHARTS.each { product, helmChart ->
        // make all image names sed-friendly
        def currentImageName = helmChart.currentImageName.replace('/', '\\/')
        def rootLevelImageName = helmChart.rootLevelImageName.replace('/', '\\/')
        sh "sed -i 's/${currentImageName}/${rootLevelImageName}/g' ${helmChart.filePath}"
    }
}

return this