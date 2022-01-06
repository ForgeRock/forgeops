/*
 * Copyright 2020-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// tag-ready-for-dev-pipelines.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status

/**
 * Tag current commit as ready-for-dev-pipelines: the tag will be use in DEV pipelines for k8s/pit1.
 */
void runStage(PipelineRunLegacyAdapter pipelineRun) {
    def tagBaseName = 'ready-for-dev-pipelines'
    def tagName = "${env.BRANCH_NAME}-${tagBaseName}"

    pipelineRun.pushStageOutcome("create-tag-${tagName}", stageDisplayName: "Tag ${tagName}") {
        node('build&&linux') {
            stage("Tag ${tagName}") {
                checkout scm
                sh "git checkout ${commonModule.FORGEOPS_GIT_COMMIT}"

                sh "git tag --force ${tagName}"
                sh "git push --force origin ${tagName}"

                return Status.SUCCESS.asOutcome()
            }
        }
    }
}

return this
