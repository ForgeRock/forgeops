/*
 * Copyright 2019-2024 Ping Identity Corporation. All Rights Reserved
 *
 * This code is to be used exclusively in connection with Ping Identity
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a
 * binding license agreement with Ping Identity Corporation.
 */


//===============================================
// Postcommit pipeline for ForgeOps Docker images
//===============================================

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status

def initialSteps() {
    properties([
            buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '20')),
            parameters(commonLodestarModule.postcommitMandatoryStages(true)),
    ])

    slackChannel = '#forgeops-team'
}

/**
 * Uses the provided pipelineRun object to run Postcommit tests.
 *
 * @param pipelineRun Used for running tests as part of the pipeline
 */
def postBuildTests(PipelineRunLegacyAdapter pipelineRun) {
    try {
        Random random = new Random()
        postcommitTestsStage.runStage(pipelineRun, random, true)
    } catch (exception) {
        sendFailedSlackNotification("Error occurred while running postcommit tests")
        throw exception
    }
}

/**
 * Uses the provided pipelineRun object to a stable tag on ForgeOps repository.
 *
 * @param pipelineRun Used to create the tag as part of the pipeline
 */
def createRepoStableTag(PipelineRunLegacyAdapter pipelineRun) {
    try {
        createRepoStableTag.runStage(pipelineRun)
    } catch (exception) {
        sendFailedSlackNotification("Error occurred while creating the stable tag on the repository")
        throw exception
    }
}

/**
 * Uses the provided pipelineRun object to create PR to Platform Images with ForgeOps commit.
 *
 * @param pipelineRun Used to create the PR as part of the pipeline
 */
def createPlatformImagesPR(PipelineRunLegacyAdapter pipelineRun) {
    try {
        createPlatformImagesPR.runStage(pipelineRun)
    } catch (exception) {
        sendFailedSlackNotification("Error occurred while creating the PR on platform-images")
        throw exception
    }
}

private void sendFailedSlackNotification(String msgDetails='') {
    currentBuild.result = 'FAILURE'
    slackUtils.sendStatusMessage(slackChannel, currentBuild.result, msgDetails)
}

def finalNotification() {
    stage('Final notification') {
        // If some of the postcommit tests fail, the plugin that manages this doesn't throw an exception,
        // but it does set the build result to UNSTABLE/FAILURE. If it does not do that => SUCCESS
        if (!currentBuild.result || currentBuild.result == 'SUCCESS') {
            currentBuild.result = 'SUCCESS'

            // Send a 'build is back to normal' notification if the previous build was not good
            if (buildIsBackToNormal()) {
                slackUtils.sendBackToNormalMessage(slackChannel)
            }
        } else {
            sendSlackNotification()
        }
    }
}

private void sendSlackNotification(String messageSuffix = '') {
    slackUtils.sendStatusMessage(slackChannel, currentBuild.result, messageSuffix)
}

return this
