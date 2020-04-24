/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.stage.FailureOutcome
import com.forgerock.pipeline.stage.Outcome
import com.forgerock.pipeline.stage.Status

/*
 * Common configuration used by several stages of the ForgeOps pipeline.
 */

/**
 * Globally scoped git commit information
 */
FORGEOPS_SHORT_GIT_COMMIT = sh(script: 'git rev-parse --short=15 HEAD', returnStdout: true).trim()

/**
 * Globally scoped git commit information
 */
FORGEOPS_GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()

/** Globally scoped git commit information for the Lodestar repo */
LODESTAR_GIT_COMMIT_FILE = 'jenkins-scripts/libs/lodestar-commit.txt'
LODESTAR_GIT_COMMIT = readFile(file: "${env.WORKSPACE}/${LODESTAR_GIT_COMMIT_FILE}").trim()

/** Root-level image names corresponding to product Helm charts and Dockerfiles in the ForgeOps repo. */
ROOT_LEVEL_IMAGE_NAMES = [
        'am'        : 'gcr.io/forgerock-io/am',
        'am-fbc'    : 'gcr.io/forgerock-io/am',
        'amster'    : 'gcr.io/forgerock-io/amster',
        'ds-empty'  : 'gcr.io/forgerock-io/ds-empty',
        'ds-cts'    : 'gcr.io/forgerock-io/ds-empty',
        'ds-idrepo' : 'gcr.io/forgerock-io/ds-empty',
        'ds-util'   : 'gcr.io/forgerock-io/ds-empty',
        'idm'       : 'gcr.io/forgerock-io/idm',
        'ig'        : 'gcr.io/forgerock-io/ig-standalone',
]

/** Helm chart file paths. Should be treated as private, although it's not possible to enforce this in Groovy. */
HELM_CHART_PATHS = [
        'am'        : 'helm/openam/values.yaml',
        'amster'    : 'helm/amster/values.yaml',
        'ds-empty'  : 'helm/ds-empty/values.yaml',
        'idm'       : 'helm/openidm/values.yaml',
        'ig'        : 'helm/openig/values.yaml',
]

/**
 * Helm data relevant to the ForgeOps pipeline. Cached to prevent repeated reading from file.
 * Should be treated as private, although it's not possible to enforce this in Groovy.
 */
helmChartCache = [:]

/** Products which have associated Helm charts. */
Collection<String> getHelmChartProductNames() {
    return HELM_CHART_PATHS.keySet()
}

/** Helm Chart data for all ForgeRock products. */
Collection<Map> getHelmCharts() {
    return getHelmChartProductNames().collect { getHelmChart(it) }
}

/**
 * Helm chart data for individual ForgeRock product.
 *
 * @param productName Product to retrieve Helm chart data for.
 * @return Helm chart data relevant to the build pipelines.
 */
Map getHelmChart(String productName) {
    if (!HELM_CHART_PATHS.containsKey(productName)) {
        error "Unknown Helm chart for '${productName}'"
    }
    if (!ROOT_LEVEL_IMAGE_NAMES.containsKey(productName)) {
        error "Unknown root-level image name '${productName}'"
    }

    def helmChartFilePath = HELM_CHART_PATHS[productName]

    if (!helmChartCache.containsKey(productName)) {
        // cache Helm chart data for future use
        def helmChartYaml = readYaml(file: helmChartFilePath)
        helmChartCache[productName] = [
            'filePath'           : helmChartFilePath,
            'rootLevelImageName' : ROOT_LEVEL_IMAGE_NAMES[productName],
            'currentImageName'   : helmChartYaml.image.repository,
            'currentTag'         : helmChartYaml.image.tag,
            'productCommit'      : helmChartYaml.image.tag.split('-').last(),
        ]
    }

    return helmChartCache[productName]
}

/** Skaffold Dockerfile paths. Should be treated as private, although it's not possible to enforce this in Groovy. */
SKAFFOLD_DOCKERFILE_PATHS = [
        // TODO remove CLOUD-2168
        //'am'        : 'docker/7.0/am/Dockerfile',
        'am-fbc'    : 'docker/7.0/am-fbc/Dockerfile',
        //'amster'    : 'docker/7.0/amster/Dockerfile',
        'ds-cts'    : 'docker/7.0/ds/cts/Dockerfile',
        'ds-util'   : 'docker/7.0/ds/dsutil/Dockerfile',
        'ds-idrepo' : 'docker/7.0/ds/idrepo/Dockerfile',
        'idm'       : 'docker/7.0/idm/Dockerfile',
        'ig'        : 'docker/7.0/ig/Dockerfile',
]

/** Products which have associated Dockerfiles. */
Collection<String> getDockerfileProductNames() {
    return SKAFFOLD_DOCKERFILE_PATHS.keySet()
}

/** Skaffold Dockerfile data for all ForgeRock products. */
Collection<Map> getDockerfiles() {
    return getDockerfileProductNames().collect { getDockerfile(it) }
}

/**
 * Skaffold Dockerfile data for individual ForgeRock product.
 *
 * @param productName Product to retrieve Dockerfile data for.
 * @return Dockerfile data relevant to the build pipelines.
 */
Map getDockerfile(String productName) {
    if (!SKAFFOLD_DOCKERFILE_PATHS.containsKey(productName)) {
        error "Unknown Dockerfile for '${productName}'"
    }
    if (!ROOT_LEVEL_IMAGE_NAMES.containsKey(productName)) {
        error "Unknown root-level image name '${productName}'"
    }

    String baseImage
    if (productName == 'am-fbc') {
        baseImage = 'am'
    } else if (productName in ['ds-cts', 'ds-util', 'ds-idrepo']) {
        baseImage = 'ds-empty'
    } else {
        baseImage = productName
    }
    String tag = getHelmChart(baseImage).currentTag

    return [
            'filePath'     : SKAFFOLD_DOCKERFILE_PATHS[productName],
            'fullImageName': "${ROOT_LEVEL_IMAGE_NAMES[productName]}:${tag}",
    ]
}

def getCurrentProductCommitHashes() {
    return [
            getHelmChart('ds-empty').productCommit,
            getHelmChart('ig').productCommit,
            getHelmChart('idm').productCommit,
            getHelmChart('am').productCommit,
    ]
}

return this
