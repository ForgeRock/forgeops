/*
 * Copyright 2019-2020 ForgeRock AS. All Rights Reserved
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

def build() {
    properties([buildDiscarder(logRotator(daysToKeepStr: '5', numToKeepStr: '5'))])

    // Abort any active builds relating to the current PR, as they are superseded by this build
    abortMultibranchPrBuilds()

    prBuild = new PullRequestBuild(steps, env, currentBuild, scm)
    bitbucketCommentId = bitbucketUtils.postMultibranchBuildStatusCommentOnPullRequest(buildStatus: 'IN PROGRESS')

    try {
        // in order to compare the PR with the target branch, we first need to fetch the target branch
        scmUtils.fetchRemoteBranch(env.CHANGE_TARGET, scmUtils.getRepoUrl())

        for (buildDirectory in buildDirectories) {
            if (imageRequiresBuild(buildDirectory['name'], buildDirectory['forceBuild'])) {
                stage("Build ${buildDirectory['name']} image") {
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
        bitbucketUtils.postMultibranchBuildStatusCommentOnPullRequest(buildStatus: 'ABORTED',
                                                                      originalCommentId: bitbucketCommentId)
        throw ex
    } catch (exception) {
        currentBuild.result = 'FAILURE'
        bitbucketUtils.postMultibranchBuildStatusCommentOnPullRequest(originalCommentId: bitbucketCommentId)
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

/**
 * Uses the provided pipelineRun object to run PR tests.
 *
 * @param pipelineRun Used for running tests as part of the pipeline
 */
def postBuildTests(PipelineRunLegacyAdapter pipelineRun) {
    try {
        Random random = new Random()
        def parallelTestsMap = [
            Spyglaas: { pit1TestStage.runStage(pipelineRun, random) },
            PyRock: { perfTestStage.runStage(pipelineRun, random) },
        ]

        parallel parallelTestsMap
        currentBuild.result = 'SUCCESS'
    } catch (FlowInterruptedException ex) {
        echo "CAUGHT FlowInterruptedException"
        currentBuild.result = 'ABORTED'
        throw ex
    } catch (exception) {
        currentBuild.result = 'FAILURE'
        throw exception
    } finally {
        bitbucketUtils.postMultibranchBuildStatusCommentOnPullRequest(originalCommentId: bitbucketCommentId)
    }
}

return this
