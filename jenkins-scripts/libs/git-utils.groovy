/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

/*
 * Git operations used by the ForgeOps pipeline.
 */

/**
 * Shallow clone a repository branch. If the branch has already been cloned, switch to it.
 *
 * @param repoUrl Url of the repository to clone.
 * @param branchName Name of the branch to clone.
 */
void shallowCloneBranch(String repoUrl, String branchName) {
    cloneBranch(repoUrl, branchName, true)
}

/**
 * Deep clone a repository branch. If the branch has already been cloned, switch to it.
 *
 * @param repoUrl Url of the repository to clone.
 * @param branchName Name of the branch to clone.
 */
void deepCloneBranch(String repoUrl, String branchName) {
    cloneBranch(repoUrl, branchName, false)
}

private void cloneBranch(String repoUrl, String branchName, boolean isShallowClone) {
    checkout([
            $class: 'GitSCM',
            branches: [[name: "refs/heads/${branchName}"]],
            userRemoteConfigs: [
                    [
                            url: repoUrl,
                            refspec: "+refs/heads/${branchName}:refs/remotes/origin/${branchName}",
                    ]
            ],
            extensions: [
                    [$class: 'LocalBranch', localBranch: branchName],
                    /* If performing a shallow clone, retrieve some history in case commits were added to the branch
                     * during the pipeline run. The 'depth' value is ignored if 'shallow' is false. */
                    [$class: 'CloneOption', honorRefspec: true, noTags: true, shallow: isShallowClone, depth: 20],
            ]
    ])
}

/**
 * Checkout the ForgeOps repository.
 *
 * @return The directory containing the checked out repository.
 */
String checkoutForgeops() {
    dir('forgeops') {
        checkout scm
        sh "git checkout ${commonModule.FORGEOPS_GIT_COMMIT}"
        return pwd()
    }
}

return this