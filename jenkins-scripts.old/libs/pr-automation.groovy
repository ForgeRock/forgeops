/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.GlobalConfig
import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status

/**
 * Merge the pull request if it is a product increment opened automatically by Rockbot.
 *
 * Typically these types of pull request are raised after a successful product postcommit build.
 * If the pull request cannot be fast-forward merged, rebase the PR - this causes a new build to run.
 *
 * @param currentBuildCommit Git commit used in this build.
 */
void mergeIfAutomatedProductVersionUpdate(PipelineRunLegacyAdapter pipelineRun, String currentBuildCommit) {
    String project = scmUtils.getProjectName()
    String repo = scmUtils.getRepoName()
    String creds = credsId()

    if (isAutomatedPullRequest()) {
        updatePrData()

        // Possible time-of-check to time-of-use race condition
        String latestPrVersion = PR_DATA.version.toString()
        String latestCommitOnPrBranch = PR_DATA.fromRef.latestCommit

        /*
         * The commit used in this build could be out of date with the PR if someone pushed while the build was running.
         * If PR is up to date and commit on target branch is the parent of this commit, merge the PR, else rebase.
         */
        if (currentBuildCommit == latestCommitOnPrBranch &&
                canDoFastForwardMerge(currentBuildCommit, PR_DATA.toRef.latestCommit)) {
            pipelineRun.pushStageOutcome(
                    "promote-to-forgeops-${env.CHANGE_TARGET}",
                    stageDisplayName: "Promote to ForgeOps") {
                bitbucketUtils.mergePullRequest(creds, project, repo, env.CHANGE_ID, latestPrVersion)
                return Status.SUCCESS.asOutcome()
            }
        } else {
            bitbucketUtils.rebasePullRequest(creds, project, repo, env.CHANGE_ID, latestPrVersion)
        }
    }
}

/** Map representation of the Pull Request. */
private Map getCurrentPrData() {
    return bitbucketUtils.getPullRequestData(
            credsId(), scmUtils.getProjectName(), scmUtils.getRepoName(), env.CHANGE_ID
    )
}

/** Update the internal pull request representation with up-to-date information. */
private void updatePrData() {
    PR_DATA = getCurrentPrData()
}

/**
 * Map representation of the pull request. Set once, when the module is loaded; may contain outdated PR information.
 * Update this value using updatePrData() when it's necessary to have up-to-date PR information.
 */
PR_DATA = getCurrentPrData()

/** Determine if this is an automated pull request. */
boolean isAutomatedPullRequest() {
    return PR_DATA.author.user.slug == GlobalConfig.FORGEOPS_AUTOMATED_PR_AUTHOR &&
            PR_DATA.title.startsWith(GlobalConfig.FORGEOPS_AUTOMATED_PR_TITLE_PREFIX)
}

/** Get the related product commit hashes for a product increment PR opened automatically by Rockbot. */
Collection<String> getPrProductCommitHashes() {
    Map<String, String> relatedCommits = [:]
    scmUtils.fetchRemoteBranch(env.CHANGE_TARGET, scmUtils.getRepoUrl())

    // Check changes to products
    commonModule.dockerImages.each { imageKey, image ->
        if (scmUtils.fileHasChangedComparedToBranch(env.CHANGE_TARGET, image.dockerfilePath)) {
            String repo = commonModule.productToRepo[imageKey]
            relatedCommits[repo] = image.productCommit
        }
    }

    // Check changes to Lodestar
    if (scmUtils.fileHasChangedComparedToBranch(env.CHANGE_TARGET, commonModule.LODESTAR_GIT_COMMIT_FILE)) {
        relatedCommits['lodestar'] = LODESTAR_GIT_COMMIT
    }

    return relatedCommits
}

/*
 * Look at git history to determine whether a fast-forward merge is possible.
 */
private boolean canDoFastForwardMerge(String currentBuildCommit, String latestCommitOnTargetBranch) {
    String project = scmUtils.getProjectName()
    String repo = scmUtils.getRepoName()

    String pullRequestParentCommit = httpUtils.sendBasicAuthJsonRequest(
            'GET',
            "${GlobalConfig.bitbucketUrl}/rest/api/1.0/projects/${project}/repos/${repo}/commits/${currentBuildCommit}",
            credsId()
    ).parents[0].id

    return pullRequestParentCommit == latestCommitOnTargetBranch
}

private String credsId() {
    return 'rockbot-backstage-credentials'
}

return this
