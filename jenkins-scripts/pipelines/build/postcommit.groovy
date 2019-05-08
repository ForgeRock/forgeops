#!/usr/bin/env groovy

//===============================================
// Postcommit pipeline for ForgeOps Docker images
//===============================================

import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

import com.forgerock.pipeline.Build

def build() {

    properties([buildDiscarder(logRotator(numToKeepStr: '20'))])

    def postcommitBuild = new Build(steps, env, currentBuild)
    def slackChannel = '#cloud-deploy-notify'
    def currentImage

    try {
        stage ('Clone repo') {
            checkout scm
            SHORT_GIT_COMMIT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
            currentBuild.displayName = "#${BUILD_NUMBER} - ${SHORT_GIT_COMMIT}"
            currentBuild.description = 'built:'
        }

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
        postcommitBuild.sendSlackNotification(
            slackChannel,
            true, // prepend @here
            "${JOB_NAME} #${BUILD_NUMBER} FAILED while building the `${currentImage}` image"
        )
        throw exception
    }
}

boolean imageRequiresBuild(String directoryName, boolean forceBuild) {
    return forceBuild || BUILD_NUMBER == '1' || scmUtils.changesInFolder("docker/${directoryName}")
}

void buildImage(String directoryName) {
    String imageBaseName = "gcr.io/forgerock-io/${directoryName}"
    String gitShaLabel = "${BASE_VERSION}-${SHORT_GIT_COMMIT}" // e.g. 7.0.0-a7267fbc

    sh "docker build --no-cache --pull --tag ${imageBaseName}:${gitShaLabel} docker/${directoryName}"
    sh "docker push ${imageBaseName}:${gitShaLabel}"
    sh "docker tag ${imageBaseName}:${gitShaLabel} ${imageBaseName}:latest"
    sh "docker push ${imageBaseName}:latest"
}

return this
