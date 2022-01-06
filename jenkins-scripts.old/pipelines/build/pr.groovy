/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

//=================================================
// Pull request pipeline for ForgeOps Docker images
//=================================================

import com.forgerock.pipeline.PullRequestBuild
import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException
import com.forgerock.pipeline.stage.Status

def initialSteps() {
    prStageName = 'PR-ALL-TESTS'
    prReportMessage = "Report is available [here](${env.JOB_URL}/${env.BUILD_NUMBER}/${prStageName}/)"

    if (params.isEmpty()) {
        properties([
                buildDiscarder(logRotator(daysToKeepStr: '5', numToKeepStr: '5')),
                parameters([
                        booleanParam(name: 'PR_pit1', defaultValue: true),
                ] + commonLodestarModule.postcommitMandatoryStages(false)),
        ])

        sendInformationMessageToPR()
    }

    // Abort any active builds relating to the current PR, as they are superseded by this build
    abortMultibranchPrBuilds()

    prBuild = new PullRequestBuild(steps, env, currentBuild, scm)
    bitbucketCommentId = bitbucketUtils.postMultibranchBuildStatusCommentOnPullRequest(
            buildStatus: 'IN PROGRESS',
            commitHash: commonModule.GIT_COMMIT
    )

    // in order to compare the PR with the target branch, we first need to fetch the target branch
    scmUtils.fetchRemoteBranch(env.CHANGE_TARGET, scmUtils.getRepoUrl())
}

def buildDockerImages(PipelineRunLegacyAdapter pipelineRun) {
    pipelineRun.pushStageOutcome('build-docker-images', stageDisplayName: 'Build Lodestar Images') {
        def currentImage
        try {
            for (buildDirectory in buildDirectories) {
                if (imageRequiresBuild(buildDirectory['name'], buildDirectory['forceBuild'])) {
                    stage("Build ${buildDirectory['name']} image") {
                        echo "Building 'docker/${buildDirectory['name']}' ..."
                        currentImage = buildDirectory['name']
                        buildImage(buildDirectory['name'])
                        currentBuild.description += " ${buildDirectory['name']}"
                    }
                } else {
                    echo "Skipping build for 'docker/${buildDirectory['name']}'"
                }
            }
        } catch (FlowInterruptedException exception) {
            sendBuildAbortedNotification()
            throw exception
        } catch (exception) {
            sendBuildFailureNotification("Error occurred while building the `${currentImage}` image")
            throw exception
        }

        return Status.SUCCESS.asOutcome()
    }
}

// Since it's not straightforward to detect changes between the PR branch and master, on the first PR build
// we build everything. This can be disabled by temporarily commenting various lines out of buildDirectories.
boolean imageRequiresBuild(String directoryName, boolean forceBuild) {
    return forceBuild || BUILD_NUMBER == '1' ||
            scmUtils.directoryContentsHaveChangedComparedToBranch(env.CHANGE_TARGET, "docker/${directoryName}")
}

void buildImage(String directoryName) {
    String imageBaseName = "gcr.io/forgerock-io/${directoryName}"
    String gitShaLabel = "${BASE_VERSION}-${commonModule.SHORT_GIT_COMMIT}" // e.g. 7.0.0-a7267fbc

    sh "docker build --no-cache --pull --tag ${imageBaseName}:${gitShaLabel} docker/${directoryName}"
}

/**
 * Uses the provided pipelineRun object to run PR tests.
 *
 * @param pipelineRun Used for running tests as part of the pipeline
 */
def postBuildTests(PipelineRunLegacyAdapter pipelineRun) {
    try {
        Random random = new Random()
        if (params.PR_pit1) {
            prTestsStage.runStage(pipelineRun, random)
        }

        if (commonLodestarModule.doRunPostcommitTests()) {
            postcommitTestsStage.runStage(pipelineRun, random, false)
        }

        commonLodestarModule.generateSummaryTestReport(prStageName)
    } catch (FlowInterruptedException exception) {
        sendBuildAbortedNotification()
        throw exception
    } catch (exception) {
        // If there is a pipeline error, or a timeout with the PIT/PERF tests, an exception is thrown.
        if (currentBuild.result != 'ABORTED') {
            commonLodestarModule.generateSummaryTestReport(prStageName)
        }
        sendBuildFailureNotification("PR tests failed. ${prReportMessage}")
        throw exception
    }
}

/** Post a comment on the PR, explaining rules and how to execute additional tests */
void sendInformationMessageToPR() {
    if (isPR()) {
        bitbucketUtils.commentOnMultibranchPullRequest(
                """#### Jenkins is building your PR
                  |If you would like to know how to configure which tests are run against your PR, click [here](https://ci.forgerock.org/job/ForgeOps-build/job/PR-${env.CHANGE_ID}/build?delay=0sec)
                """.stripMargin()
        )
    }
}

def sendBuildAbortedNotification() {
    currentBuild.result = 'ABORTED'
    bitbucketUtils.postMultibranchBuildStatusCommentOnPullRequest(
            commitHash: commonModule.GIT_COMMIT,
            originalCommentId: bitbucketCommentId
    )
}

def sendBuildFailureNotification(String messageSuffix) {
    currentBuild.result = 'FAILURE'
    bitbucketUtils.postMultibranchBuildStatusCommentOnPullRequest(
            commitHash: commonModule.GIT_COMMIT,
            originalCommentId: bitbucketCommentId,
            messageSuffix: messageSuffix
    )
}

def finalNotification() {
    stage('Final notification') {
        // If some of the PR tests fail, the plugin that manages this doesn't throw an exception, but
        // it does set the build result to UNSTABLE/FAILURE. If it didn't do that => SUCCESS
        def message = ''
        if (prStageName != '') {
            message = prReportMessage
        }
        if (!currentBuild.result || currentBuild.result == 'SUCCESS') {
            currentBuild.result = 'SUCCESS'
        } else {
            message = "PR tests failed."
        }
        bitbucketUtils.postMultibranchBuildStatusCommentOnPullRequest(
                commitHash: commonModule.GIT_COMMIT,
                originalCommentId: bitbucketCommentId,
                messageSuffix: message
        )
    }
}

return this
