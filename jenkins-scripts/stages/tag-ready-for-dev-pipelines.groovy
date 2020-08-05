/*
 * Copyright 2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun
import com.forgerock.pipeline.stage.Status

/**
 * Tag current commit as ready-for-dev-pipelines: the tag will be use in DEV pipelines for k8s/pit1.
 */
void runStage(PipelineRun pipelineRun) {
    def tagName = 'ready-for-dev-pipelines'

    pipelineRun.pushStageOutcome(tagName, stageDisplayName: "Tag ${tagName}") {
        node('build&&linux') {
            stage("Tag ${tagName}") {
                pipelineRun.updateStageStatusAsInProgress()

                checkout scm
                sh "git checkout ${commonModule.FORGEOPS_GIT_COMMIT}"

                sh "git tag --force ${tagName}"
                sh "git push --force origin ${tagName}"

                return Status.SUCCESS.asOutcome()
            }
        }
    }
}
