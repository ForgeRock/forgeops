/*
 * Copyright 2019-2023 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

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
String calculatePlatformImagesTag() {
    return "${calculatePlatformImagesBranch()}-ready-for-dev-pipelines"
}
DEFAULT_PLATFORM_IMAGES_TAG = calculatePlatformImagesTag()

String calculatePlatformImagesBranch() {
    def branchName = isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME
    if (branchName.startsWith('release/')) {
        def versionParts = (branchName - 'release/').tokenize('-')[0].tokenize('.')
        return "sustaining/${versionParts[0]}.${versionParts[1]}.x"
    } else {
        return 'master'
    }
}

/** Revision of platform-images repo used for k8s and platform integration/perf tests. */
platformImagesRevision = bitbucketUtils.getLatestCommitHash(
        'cloud',
        'platform-images',
        DEFAULT_PLATFORM_IMAGES_TAG)

/** Revision of Lodestar framework used for K8s and platform integration/perf tests. */
lodestarFileContent = bitbucketUtils.readFileContent(
        'cloud',
        'platform-images',
        platformImagesRevision,
        'lodestar.json').trim()
lodestarRevision = readJSON(text: lodestarFileContent)['gitCommit']

/** Does the branch support PIT tests */
boolean branchSupportsPitTests() {
    def supportedBranchPrefixes = [
            'master',
            'idcloud-',
            'release/',
            'sustaining/',
            'preview/',
    ]
    String branch = isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME
    return supportedBranchPrefixes.any { it -> branch.startsWith(it) }
}

/** Does the branch support PaaS releases */
// TODO Improve the code below to take into account new sustaining branches
// We should only promote version >= 7.1.0
// To be discussed with Bruno and Robin
boolean branchSupportsIDCloudReleases() {
    def branchName = isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME
    return branchName.equals('master') \
            || branchName.equals('feature/config') \
            || branchName.equals('release/7.1.0') \
            || branchName.startsWith('idcloud-') \
            || branchName.startsWith('sustaining/') \
            || branchName.startsWith('preview/')
}

void buildImage(String directoryName, String imageName, String arguments) {

}

return this
