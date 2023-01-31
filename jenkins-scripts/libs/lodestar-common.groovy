/*
 * Copyright 2021-2022 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// lodestar-common.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status
import com.forgerock.pipeline.stage.Outcome
import com.forgerock.pipeline.stage.FailureOutcome

def getPromotedProductTag(platformImagesRevision, productName) {
    def content = bitbucketUtils.readFileContent(
            'cloud',
            'platform-images',
            platformImagesRevision,
            "${productName}.json").trim()
    return readJSON(text: content)['imageTag']
}

def getPromotedProductRepo(platformImagesRevision, productName) {
    def content = bitbucketUtils.readFileContent(
            'cloud',
            'platform-images',
            platformImagesRevision,
            "${productName}.json").trim()
    return readJSON(text: content)['imageName']
}

def getPromotedProductCommit(platformImagesRevision, productName) {
    def content = bitbucketUtils.readFileContent(
            'cloud',
            'platform-images',
            platformImagesRevision,
            "${productName}.json").trim()
    return readJSON(text: content)['gitCommit']
}

def getPromotedProductImageTag(platformImagesRevision, productName) {
    def content = bitbucketUtils.readFileContent(
            'cloud',
            'platform-images',
            platformImagesRevision,
            "${productName}.json").trim()
    return readJSON(text: content)['imageTag']
}

fraasProductionTag = '7.2.0'
forgeopsFraasProduction = getPromotedProductCommit(fraasProductionTag, 'forgeops')

allStagesCloud = [:]

boolean doRunPostcommitTests() {
    return !params.isEmpty() && params.any { name, value -> name.startsWith('Postcommit_') && value }
}

ArrayList commonParams() {
    return [
        string(name: 'Lodestar_ref', defaultValue: '',
                description: 'Can be a branch, tag or commit. Leave empty for latest promoted')
    ]
}

ArrayList postcommitMandatoryStages(boolean enabled) {
    return [
        booleanParam(name: 'Postcommit_pit1', defaultValue: enabled),
        booleanParam(name: 'Postcommit_perf_postcommit', defaultValue: enabled),
        booleanParam(name: 'Postcommit_perf_restore', defaultValue: enabled),
        booleanParam(name: 'Postcommit_am_k8s_postcommit', defaultValue: enabled),
        booleanParam(name: 'Postcommit_am_k8s_upgrade', defaultValue: enabled),
        booleanParam(name: 'Postcommit_ds_k8s_postcommit', defaultValue: enabled),
        booleanParam(name: 'Postcommit_ds_k8s_upgrade', defaultValue: enabled),
        booleanParam(name: 'Postcommit_idm_k8s_postcommit', defaultValue: enabled),
        booleanParam(name: 'Postcommit_idm_k8s_upgrade', defaultValue: enabled),
        booleanParam(name: 'Postcommit_ig_k8s_postcommit', defaultValue: enabled) ,
        booleanParam(name: 'Postcommit_ig_k8s_upgrade', defaultValue: enabled),
        booleanParam(name: 'Postcommit_platform_ui', defaultValue: enabled),
        booleanParam(name: 'Postcommit_set_images', defaultValue: enabled),
    ]
}

def getDefaultConfig(Random random, String stageName) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def randomNumber = random.nextInt(99999) + 100000 // 6 digit random number to compute to namespace
    def config = [
        STASH_PLATFORM_IMAGES_REF           : commonModule.platformImagesRevision,
        STASH_FORGEOPS_REF                  : commonModule.GIT_COMMIT,
        STASH_LODESTAR_REF                  : params.Lodestar_ref, // If empty, lodestar ref is computed from platform images
        DEPLOYMENT_NAMESPACE                : cloud_config.spyglaasConfig()['DEPLOYMENT_NAMESPACE'] + '-' + randomNumber,
        REPORT_NAME_PREFIX                  : normalizedStageName,
        PIPELINE_NAME                       : 'Postcommit-Forgeops',
        DO_RECORD_RESULT                    : false,
        GATLING_PASS_PERCENTAGE             : 90,
    ]
    return config
}

def runCommon(PipelineRunLegacyAdapter pipelineRun, String stageName, Map stagesCloud, Closure process) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        dockerUtils.insideGoogleCloudImage(dockerfilePath: 'docker/google-cloud', getDockerfile: true) {
            stage(stageName) {
                dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                    process()
                }
                allStagesCloud[normalizedStageName] = stagesCloud[normalizedStageName]
                return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
            }
        }
    }
}

def runSpyglaas(PipelineRunLegacyAdapter pipelineRun, Random random, String stageName, Map config) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def testConfig = getDefaultConfig(random, stageName) + config
    def stagesCloud = [:]
    stagesCloud[normalizedStageName] = dashboard_utils.spyglaasStageCloud(normalizedStageName)

    runCommon(pipelineRun, stageName, stagesCloud) {
        withGKESpyglaasNoStages(testConfig)
    }
}

def runPyrock(PipelineRunLegacyAdapter pipelineRun, Random random, String stageName, Map config) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def testConfig = getDefaultConfig(random, stageName) + config
    def stagesCloud = [:]
    def testName = cloud_utils.pyrockGetTestName(testConfig)
    stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud(normalizedStageName)

    runCommon(pipelineRun, stageName, stagesCloud) {
        withGKEPyrockNoStages(testConfig)
    }
}

def runUpgrade(PipelineRunLegacyAdapter pipelineRun, Random random, String stageName, Map deploymentConfig,
               Map testConfig) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def stagesCloud = [:]
    def deploymentReportNamePrefix = deploymentConfig.REPORT_NAME_PREFIX
    def deploymentStageName = dashboard_utils.normalizeStageName(deploymentReportNamePrefix)
    stagesCloud[deploymentStageName] = dashboard_utils.spyglaasStageCloud(deploymentStageName)
    def testReportNamePrefix = testConfig.REPORT_NAME_PREFIX
    def testStageName = dashboard_utils.normalizeStageName(testReportNamePrefix)
    stagesCloud[testStageName] = dashboard_utils.spyglaasStageCloud(testStageName)

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        dockerUtils.insideGoogleCloudImage(dockerfilePath: 'docker/google-cloud', getDockerfile: true) {
            stage(stageName) {
                try {
                    dashboard_utils.determineUnitOutcome(stagesCloud[deploymentStageName]) {
                        withGKESpyglaasNoStages(getDefaultConfig(random, deploymentStageName) + deploymentConfig)
                    }
                    allStagesCloud[deploymentReportNamePrefix] = stagesCloud[deploymentStageName]

                    dashboard_utils.determineUnitOutcome(stagesCloud[testStageName]) {
                        withGKESpyglaasNoStages(getDefaultConfig(random, testStageName) + testConfig)
                    }
                    allStagesCloud[testReportNamePrefix] = stagesCloud[testStageName]
                } finally {
                    // In the deployment part the cleanup is disabled to be able to run the test part
                    // But if the deployment part fails we need to do the cleanup to remove the namespace
                    sh("./cleanup.py --namespace=${deploymentConfig.DEPLOYMENT_NAMESPACE}")
                }
                return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
            }
        }
    }
}

def runPlatformUi(PipelineRunLegacyAdapter pipelineRun, Random random, String stageName, Map config) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def testConfig = getDefaultConfig(random, stageName) + config +
            [EXT_PLATFORM_IMAGES_REF: commonModule.platformImagesRevision]
    def stagesCloud = [:]
    stagesCloud[normalizedStageName] = dashboard_utils.spyglaasStageCloud(normalizedStageName)

    def reportUrl = "${env.BUILD_URL}/${normalizedStageName}/"

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('gce-vm-lodestar-n1-standard-8') {
            stage(stageName) {
                try {
                    def platformUiRevision
                    def platformUiImageTag
                    // When the UI tests are executed on:
                    // - master branch we use the UI commit from platform-images master
                    // - sustaining/7.2.x we use the 7.2.0 UI tag
                    // - otherwise we use the ID_Cloud_Production tag
                    if ('master' in [env.CHANGE_TARGET, env.BRANCH_NAME]) {
                        platformUiRevision = getPromotedProductCommit(platformImagesRevision, 'ui')
                        platformUiImageTag = getPromotedProductImageTag(platformImagesRevision, 'ui')
                    } else if ('sustaining/7.2.x' in [env.CHANGE_TARGET, env.BRANCH_NAME] || 'release/7.2.0' in [env.CHANGE_TARGET, env.BRANCH_NAME]) {
                        platformUiRevision = bitbucketUtils.getLatestCommitHash(
                                'ui',
                                'platform-ui',
                                '7.2.0')
                        platformUiImageTag = "7.2.0-${platformUiRevision}"
                    } else {
                        platformUiRevision = bitbucketUtils.getLatestCommitHash(
                                'ui',
                                'platform-ui',
                                'ID_Cloud_Production')

                        def platformUIShortRevision = platformUiRevision.substring(0, 11)
                        def script = "git log --oneline | grep 'UI update to ${platformUIShortRevision}' | cut -d' ' -f1"
                        def platformImagesRevision = sh(script: script, returnStdout: true).trim()
                        if (platformImagesRevision == '') {
                            error "Impossible to find ID_Cloud_Production commit ${platformUIShortRevision} " +
                                    "in platform-images git log.\n" +
                                    "Finding the docker image tag requires using a platform-ui commit that" +
                                    " is listed in platform-images git log."
                        }

                        def content = bitbucketUtils.readFileContent(
                                'cloud',
                                'platform-images',
                                platformImagesRevision,
                                "ui.json").trim()
                        platformUiImageTag = readJSON(text: content)['imageTag']
                    }

                    // Get platform-ui tests from corresponding commit
                    dir("platform-ui") {
                        localGitUtils.deepCloneBranch('ssh://git@stash.forgerock.org:7999/ui/platform-ui.git',
                                'master')
                        sh "git checkout ${platformUiRevision}"
                        uiTestsStage = load('jenkins-scripts/stages/ui-tests.groovy')
                    }

                    // Set UI image tag to the corresponding commit
                    testConfig.COMPONENTS_ADMINUI_IMAGE_TAG = platformUiImageTag
                    testConfig.COMPONENTS_ENDUSERUI_IMAGE_TAG = platformUiImageTag
                    testConfig.COMPONENTS_LOGINUI_IMAGE_TAG = platformUiImageTag

                    def uiTestConfig = [
                            containerRunOptions : cloud_utils.getUiContainerRunOptions(testConfig),
                            deploymentNamespace : testConfig.DEPLOYMENT_NAMESPACE,
                    ]

                    uiTestsStage.runTests(uiTestConfig, normalizedStageName, normalizedStageName,
                            commonModule.lodestarRevision)

                    allStagesCloud[normalizedStageName] = stagesCloud[normalizedStageName]
                    allStagesCloud[normalizedStageName].numFailedTests = 0
                    allStagesCloud[normalizedStageName].reportUrl = reportUrl
                } catch (Exception e) {
                    print(e.getMessage())
                    allStagesCloud[normalizedStageName] = stagesCloud[normalizedStageName]
                    allStagesCloud[normalizedStageName].numFailedTests = 1
                    allStagesCloud[normalizedStageName].reportUrl = reportUrl
                    allStagesCloud[normalizedStageName].exception = e
                    return new FailureOutcome(e, reportUrl)
                }
                return new Outcome(Status.SUCCESS, reportUrl)
            }
        }
    }
}

def generateSummaryTestReport(String stageName) {
    privateWorkspace {
        dashboard_utils.createAndPublishSummaryReport(allStagesCloud, stageName, '', false, stageName,
                "${stageName}.html")
    }
}

return this
