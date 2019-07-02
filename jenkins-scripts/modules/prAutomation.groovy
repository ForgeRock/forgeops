import com.forgerock.pipeline.GlobalConfig

/**
 * Merge the pull request if it is a product increment opened automatically by Rockbot.
 *
 * Typically these types of pull request are raised after a successful product postcommit build.
 * If the pull request cannot be fast-forward merged, rebase the PR - this causes a new build to run.
 *
 * @param currentBuildCommit Git commit used in this build.
 */
void mergeIfAutomatedProductVersionUpdate(String currentBuildCommit) {
    String project = scmUtils.getProjectName()
    String repo = scmUtils.getRepoName()
    String creds = credsId()

    Map prData = bitbucketUtils.getPullRequestData(creds, project, repo, env.CHANGE_ID)

    if (prData.author.user.slug == GlobalConfig.FORGEOPS_AUTOMATED_PR_AUTHOR &&
            prData.title.startsWith(GlobalConfig.FORGEOPS_AUTOMATED_PR_TITLE_PREFIX)) {
        // Possible time-of-check to time-of-use race condition
        String latestPrVersion = bitbucketUtils.getCurrentPullRequestVersion(creds, project, repo, env.CHANGE_ID)
        String latestCommitOnPrBranch = prData.fromRef.latestCommit

        /*
         * The commit used in this build could be out of date with the PR if someone pushed while the build was running.
         * If PR is up to date and commit on target branch is the parent of this commit, merge the PR, else rebase.
         */
        if (currentBuildCommit == latestCommitOnPrBranch &&
                canDoFastForwardMerge(currentBuildCommit, prData.toRef.latestCommit)) {
            bitbucketUtils.mergePullRequest(creds, project, repo, env.CHANGE_ID, latestPrVersion)
        } else {
            bitbucketUtils.rebasePullRequest(creds, project, repo, env.CHANGE_ID, latestPrVersion)
        }
    }
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
