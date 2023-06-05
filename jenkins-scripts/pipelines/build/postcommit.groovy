/*
 * Copyright 2019-2022 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

//===============================================
// Postcommit pipeline for ForgeOps Docker images
//===============================================

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status

def initialSteps() {
    properties([
            buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '20')),
            parameters(commonLodestarModule.commonParams() + commonLodestarModule.postcommitMandatoryStages(true)),
    ])

    slackChannel = '#forgeops-notify'
}

def buildDockerImages(PipelineRunLegacyAdapter pipelineRun) {
    pipelineRun.pushStageOutcome('build-docker-images', stageDisplayName: 'Build Forgeops Images') {
        for (buildDirectory in buildDirectories) {
            def directoryName = "${buildDirectory['folder']}/${buildDirectory['name']}"
            try {
                stage("Build ${directoryName} image") {
                    echo "Building 'docker/${directoryName}' ..."
                    String imageBaseName = "gcr.io/forgerock-io/${buildDirectory['folder']}-${buildDirectory['name']}"
                    // e.g. 7.2.0-a7267fbc
                    String gitShaLabel = "${commonModule.BASE_VERSION}-${commonModule.SHORT_GIT_COMMIT}"

                    sh commands("cd docker/${buildDirectory['folder']}",
                            "docker build --no-cache --pull --tag ${imageBaseName}:${gitShaLabel} ${buildDirectory['arguments']}")
                    currentBuild.description += " ${directoryName}"
                }
            } catch (exception) {
                sendFailedSlackNotification("Error occurred while building the `${directoryName}` image")
                throw exception
            }
        }

        return Status.SUCCESS.asOutcome()
    }
}

boolean imageRequiresBuild(String directoryName, boolean forceBuild) {
    return forceBuild ||
            scmUtils.directoryContentsHaveChangedSincePreviousBuild("docker/${directoryName}")
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
 * Uses the provided pipelineRun object create PR to Platform Images with ForgeOps commit.
 *
 * @param pipelineRun Used for running tests as part of the pipeline
 */
def createPlatformImagesPR(PipelineRunLegacyAdapter pipelineRun) {
    try {
        createPlatformImagesPR.runStage(pipelineRun)
    } catch (exception) {
        sendFailedSlackNotification("Error occurred while running postcommit tests")
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

return this
