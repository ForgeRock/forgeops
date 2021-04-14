/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.forgeops.DockerImage

/*
 * Common configuration used by several stages of the ForgeOps pipeline.
 */

/**
 * Globally scoped git commit information
 */
FORGEOPS_SHORT_GIT_COMMIT = sh(script: 'git rev-parse --short=15 HEAD', returnStdout: true).trim()
FORGEOPS_GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
FORGEOPS_GIT_COMMITTER = sh(returnStdout: true, script: 'git show -s --pretty=%cn').trim()
FORGEOPS_GIT_MESSAGE = sh(returnStdout: true, script: 'git show -s --pretty=%s').trim()
FORGEOPS_GIT_COMMITTER_DATE = sh(returnStdout: true, script: 'git show -s --pretty=%cd --date=iso8601').trim()
FORGEOPS_GIT_BRANCH = env.JOB_NAME.replaceFirst(".*/([^/?]+).*", "\$1").replaceAll("%2F", "/")

/** Globally scoped git commit information for the Lodestar repo */
LODESTAR_GIT_COMMIT_FILE = 'jenkins-scripts/libs/lodestar-commit.txt'

String getLodestarCommit() {
    return readFile(file: "${env.WORKSPACE}/${LODESTAR_GIT_COMMIT_FILE}").trim()
}
LODESTAR_GIT_COMMIT = getLodestarCommit()

/** Docker image metadata for individual ForgeRock products. */
dockerImages = [
        'am'        : DockerImagePromotion.load('docker/7.0/am/Dockerfile', 'gcr.io/forgerock-io/am-base', steps),
        'am-config-upgrader' : DockerImagePromotion.load('docker/7.0/am-config-upgrader/Dockerfile', 'gcr.io/forgerock-io/am-config-upgrader', steps),
        'amster'    : DockerImagePromotion.load('docker/7.0/amster/Dockerfile', 'gcr.io/forgerock-io/amster', steps),
        'ds-cts'    : DockerImagePromotion.load('docker/7.0/ds/cts/Dockerfile', 'gcr.io/forgerock-io/ds', steps),
        'ds-util'   : DockerImagePromotion.load('docker/7.0/ds/dsutil/Dockerfile', 'gcr.io/forgerock-io/ds', steps),
        'ds-idrepo' : DockerImagePromotion.load('docker/7.0/ds/idrepo/Dockerfile', 'gcr.io/forgerock-io/ds', steps),
        'ds-proxy'  : DockerImagePromotion.load('docker/7.0/ds/proxy/Dockerfile', 'gcr.io/forgerock-io/ds', steps),
        'idm'       : DockerImagePromotion.load('docker/7.0/idm/Dockerfile', 'gcr.io/forgerock-io/idm', steps),
        'ig'        : DockerImagePromotion.load('docker/7.0/ig/Dockerfile', 'gcr.io/forgerock-io/ig', steps),
]

productToRepo = [
        'am' : 'openam',
        'am-config-upgrader' : 'openam',
        'amster' : 'openam',
        'ds-cts' : 'opendj',
        'ds-util' : 'opendj',
        'ds-idrepo' : 'opendj',
        'ds-proxy' : 'opendj',
        'idm' : 'openidm',
        'ig' : 'openig',
]

DockerImagePromotion getDockerImage(String productName) {
    if (!dockerImages.containsKey(productName)) {
        error "No Dockerfile for image '${productName}'"
    }
    return dockerImages[productName]
}

String getCurrentTag(String productName) {
    return getDockerImage(productName).tag
}

/** Does the branch support PaaS releases */
// TODO Improve the code below to take into account new sustaining branches
// We should only promote version >= 7.1.0
// To be discussed with Bruno and Robin
boolean branchSupportsIDCloudReleases() {
    return 'master' in [env.CHANGE_TARGET, env.BRANCH_NAME] \
            || (!isPR() && ("${env.BRANCH_NAME}".startsWith('idcloud-') || "${env.BRANCH_NAME}" == 'sustaining/7.1.x')) \
            || (isPR() && ("${env.CHANGE_TARGET}".startsWith('idcloud-') || "${env.CHANGE_TARGET}" == 'sustaining/7.1.x'))
}

def getCurrentProductCommitHashes() {
    return [
            'forgeops' : commonModule.FORGEOPS_GIT_COMMIT,
            'opendj' : getDockerImage('ds-idrepo').productCommit,
            'openig' : getDockerImage('ig').productCommit,
            'openidm' : getDockerImage('idm').productCommit,
            'openam' : getDockerImage('am').productCommit,
            'lodestar' : getLodestarCommit()
    ]
}

class DockerImagePromotion implements Serializable {
    DockerImage dockerImage
    String rootLevelBaseImageName

    private DockerImagePromotion(DockerImage dockerImage, String rootLevelBaseImageName) {
        this.dockerImage = dockerImage
        this.rootLevelBaseImageName = rootLevelBaseImageName
    }

    static DockerImagePromotion load(String dockerfilePath, String rootLevelBaseImageName, def steps) {
        return new DockerImagePromotion(DockerImage.load(dockerfilePath, steps), rootLevelBaseImageName)
    }

    String getDockerfilePath() { return dockerImage.getDockerfilePath() }
    String getBaseImageName() { return dockerImage.getBaseImageName() }
    String getTag() { return dockerImage.getTag() }
    String getProductCommit() { return dockerImage.getProductCommit() }

    // Overridden methods have to be annotated with @NonCPS to work properly.
    // See https://www.jenkins.io/doc/book/pipeline/cps-method-mismatches/#overrides-of-non-cps-transformed-methods
    @NonCPS
    String toString() {
        return "${dockerImage.toString()}, rootLevelBaseImageName: ${rootLevelBaseImageName}".toString()
    }
}

return this
