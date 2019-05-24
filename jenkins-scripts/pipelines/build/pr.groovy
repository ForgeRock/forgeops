#!/usr/bin/env groovy

//=================================================
// Pull request pipeline for ForgeOps Docker images
//=================================================

import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

import com.forgerock.pipeline.PullRequestBuild

def build() {

    properties([buildDiscarder(logRotator(daysToKeepStr: '14', numToKeepStr: '10'))])

    def prBuild = new PullRequestBuild(steps, env, currentBuild, scm)
    def bitbucketCommentId = prBuild.commentOnPullRequest(buildStatus: 'IN PROGRESS')

    try {
        def repoUrl = "${scm.getRepositoryByName('origin').getURIs()[0]}"
        scmUtils.fetchRemoteBranch(env.CHANGE_TARGET, repoUrl)

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

        currentBuild.result = 'SUCCESS'
        prBuild.commentOnPullRequest(originalCommentId: bitbucketCommentId)

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
    String gitShaLabel = "${BASE_VERSION}-${SHORT_GIT_COMMIT}" // e.g. 7.0.0-a7267fbc

    sh "docker build --no-cache --pull --tag ${imageBaseName}:${gitShaLabel} docker/${directoryName}"
}

return this
