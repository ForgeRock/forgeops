/*
 * Copyright 2024 Ping Identity Corporation. All Rights Reserved
 *
 * This code is to be used exclusively in connection with Ping Identity
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a
 * binding license agreement with Ping Identity Corporation.
 */

// create-repo-stable-tag.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status

/** Create a stable tag on the ForgeOps repo when all the tests are passed */
void runStage(PipelineRunLegacyAdapter pipelineRun) {
    String GIT_BRANCH_TAG = (isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME).replace('/', '-')

    stage ('Create Repo Stable Tag') {
        pipelineRun.pushStageOutcome('create-repo-stable-tag', stageDisplayName: 'Create Repo Stable Tag') {
            privateWorkspace {
                checkout scm
                sh "git checkout ${commonModule.GIT_COMMIT}"
                gitUtils.setupDefaultUser()
                
                sh "git tag --force ${GIT_BRANCH_TAG}-stable"
                sh "git push --force origin ${GIT_BRANCH_TAG}-stable"

                return Status.SUCCESS.asOutcome()
            }
        }
    }
}

return this
