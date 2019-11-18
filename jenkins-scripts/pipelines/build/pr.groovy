/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

//=================================================
// Pull request pipeline for ForgeOps Docker images
//=================================================

import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

import com.forgerock.pipeline.PullRequestBuild
import com.forgerock.pipeline.reporting.PipelineRun

def build() {

    properties([buildDiscarder(logRotator(daysToKeepStr: '14', numToKeepStr: '10'))])

    // Abort any active builds relating to the current PR, as they are superseded by this build
    abortMultibranchPrBuilds()

    prBuild = new PullRequestBuild(steps, env, currentBuild, scm)
    bitbucketCommentId = prBuild.commentOnPullRequest(buildStatus: 'IN PROGRESS')

    try {
        // in order to compare the PR with the target branch, we first need to fetch the target branch
        scmUtils.fetchRemoteBranch(env.CHANGE_TARGET, scmUtils.getRepoUrl())

        for (buildDirectory in buildDirectories) {
            if (imageRequiresBuild(buildDirectory['name'], buildDirectory['forceBuild'])) {
                stage ("Build ${buildDirectory['name']} image") {
                    echo "Building 'docker/${buildDirectory['name']}' ..."
                    buildImage(buildDirectory['name'])
                    currentBuild.description += " ${buildDirectory['name']}"
                }
            } else {
                echo "Skipping build for 'docker/${buildDirectory['name']}'"
            }
        }
    } catch (FlowInterruptedException ex) {
        currentBuild.result = 'ABORTED'
        prBuild.commentOnPullRequest(buildStatus: 'ABORTED', originalCommentId: bitbucketCommentId)
        throw ex
    } catch (exception) {
        currentBuild.result = 'FAILURE'
        prBuild.commentOnPullRequest(originalCommentId: bitbucketCommentId)
        throw exception
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
    String gitShaLabel = "${BASE_VERSION}-${commonModule.FORGEOPS_SHORT_GIT_COMMIT}" // e.g. 7.0.0-a7267fbc

    sh "docker build --no-cache --pull --tag ${imageBaseName}:${gitShaLabel} docker/${directoryName}"
}

def postBuildTests(PipelineRun pipelineRun) {

    try {
        // PIT1 helm tests
        pit1TestStage.runStage(pipelineRun, 'PIT1 Helm')

        // PIT1 kustomize tests
        pit1TestStage.runStage(pipelineRun, 'PIT1 Kustomize', true)

        currentBuild.result = 'SUCCESS'
        prBuild.commentOnPullRequest(originalCommentId: bitbucketCommentId)
    }
    catch (exception) {
        currentBuild.result = 'FAILURE'
        prBuild.commentOnPullRequest(originalCommentId: bitbucketCommentId)
        throw exception
    }
}

return this
