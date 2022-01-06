/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.GlobalConfig

/*
 * Common configuration used by several stages of the ForgeOps pipeline.
 */

/**
 * Globally scoped git commit information
 */
SHORT_GIT_COMMIT = sh(script: 'git rev-parse --short=15 HEAD', returnStdout: true).trim()
GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
GIT_COMMITTER = sh(returnStdout: true, script: 'git show -s --pretty=%cn').trim()
GIT_MESSAGE = sh(returnStdout: true, script: 'git show -s --pretty=%s').trim()
GIT_COMMITTER_DATE = sh(returnStdout: true, script: 'git show -s --pretty=%cd --date=iso8601').trim()
GIT_BRANCH = env.JOB_NAME.replaceFirst(".*/([^/?]+).*", "\$1").replaceAll("%2F", "/")

/** Default platform-images tag corresponding to this branch (or the PR target branch, if this is a PR build) */
DEFAULT_PLATFORM_IMAGES_TAG = "${isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME}-ready-for-dev-pipelines"

/** Revision of platform-images repo used for k8s and platform integration/perf tests. */
platformImagesRevision = bitbucketUtils.getLatestCommitHash(
        GlobalConfig.stashNotifierCredentialsId,
        'cloud',
        'platform-images',
        env.STASH_PLATFORM_IMAGES_BRANCH ?: DEFAULT_PLATFORM_IMAGES_TAG)

/** Revision of Lodestar framework used for K8s and platform integration/perf tests. */
lodestarFileContent = bitbucketUtils.readFileContent(
        'cloud',
        'platform-images',
        platformImagesRevision,
        'lodestar.json').trim()
lodestarRevision = readJSON(text: lodestarFileContent)['gitCommit']

/** Does the branch support PaaS releases */
// TODO Improve the code below to take into account new sustaining branches
// We should only promote version >= 7.1.0
// To be discussed with Bruno and Robin
boolean branchSupportsIDCloudReleases() {
    return 'master' in [env.CHANGE_TARGET, env.BRANCH_NAME] \
            || 'feature/config' in [env.CHANGE_TARGET, env.BRANCH_NAME] \
            || 'release/7.1.0' in [env.CHANGE_TARGET, env.BRANCH_NAME] \
            || (!isPR() && ("${env.BRANCH_NAME}".startsWith('idcloud-') || "${env.BRANCH_NAME}" == 'sustaining/7.1.x')) \
            || (isPR() && ("${env.CHANGE_TARGET}".startsWith('idcloud-') || "${env.CHANGE_TARGET}" == 'sustaining/7.1.x'))
}

return this
