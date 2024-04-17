/*
 * Copyright 2019-2024 Ping Identity Corporation. All Rights Reserved
 * 
 * This code is to be used exclusively in connection with Ping Identity 
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a 
 * binding license agreement with Ping Identity Corporation.
 */

/*
 * Git operations used by the ForgeOps pipeline.
 */

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

return this