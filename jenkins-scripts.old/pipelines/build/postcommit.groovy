/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

//===============================================
// Postcommit pipeline for ForgeOps Docker images
//===============================================

import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

import com.forgerock.pipeline.Build
import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

def build() {

    properties([
        buildDiscarder(logRotator(numToKeepStr: '20'))
    ])

    postcommitBuild = new Build(steps, env, currentBuild)
    def currentImage

    try {
        for (buildDirectory in buildDirectories) {
            if (imageRequiresBuild(buildDirectory['name'], buildDirectory['forceBuild'])) {
                stage ("Build ${buildDirectory['name']} image") {
                    echo "Building 'docker/${buildDirectory['name']}' ..."
                    currentImage = buildDirectory['name']
                    buildImage(buildDirectory['name'])
                    currentBuild.description += " ${buildDirectory['name']}"
                }
            } else {
                echo "Skipping build for 'docker/${buildDirectory['name']}'"
            }
        }
    } catch (FlowInterruptedException ex) {
        currentBuild.result = 'ABORTED'
        throw ex
    } catch (exception) {
        currentBuild.result = 'FAILURE'
        sendSlackNotification("Error occurred while building the `${currentImage}` image")
        throw exception
    }
}

boolean imageRequiresBuild(String directoryName, boolean forceBuild) {
    return forceBuild || BUILD_NUMBER == '1' ||
            scmUtils.directoryContentsHaveChangedSincePreviousBuild("docker/${directoryName}")
}

void buildImage(String directoryName) {
    String imageBaseName = "gcr.io/forgerock-io/${directoryName}"
    String gitShaLabel = "${BASE_VERSION}-${commonModule.FORGEOPS_SHORT_GIT_COMMIT}" // e.g. 7.0.0-a7267fbc

    sh "docker build --no-cache --pull --tag ${imageBaseName}:${gitShaLabel} docker/${directoryName}"
    if (env.BRANCH_NAME == 'master') {
        sh "docker push ${imageBaseName}:${gitShaLabel}"
        sh "docker tag ${imageBaseName}:${gitShaLabel} ${imageBaseName}:latest"
        sh "docker push ${imageBaseName}:latest"
    }
}

/**
 * Uses the provided pipelineRun object to run Postcommit tests.
 *
 * @param pipelineRun Used for running tests as part of the pipeline
 */
def postBuildTests(PipelineRunLegacyAdapter pipelineRun) {
    try {
        Random random = new Random()
        def parallelTestsMap = [
            'PIT1': { pit1TestStage.runStage(pipelineRun, random) },
            'Basic Perf': { perfTestStage.runStage(pipelineRun, random) },
        ]

        parallel parallelTestsMap
        currentBuild.result = 'SUCCESS'
    } catch (exception) {
        currentBuild.result = 'FAILURE'
        sendSlackNotification("Error occurred while running postcommit tests")
        throw exception
    }
}

private void sendSlackNotification(String msgDetails) {
    slackUtils.sendStatusMessage('#cloud-deploy-notify', currentBuild.result, msgDetails)
}

return this
