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

fraasProductionTag = 'fraas-production'
productPostcommitStable = 'postcommit-stable'

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
        booleanParam(name: 'Postcommit_am_basic_perf', defaultValue: enabled),
        booleanParam(name: 'Postcommit_ds_k8s_postcommit', defaultValue: enabled),
        booleanParam(name: 'Postcommit_ds_k8s_upgrade', defaultValue: enabled),
        booleanParam(name: 'Postcommit_ds_basic_perf', defaultValue: enabled),
        booleanParam(name: 'Postcommit_idm_k8s_postcommit', defaultValue: enabled),
        booleanParam(name: 'Postcommit_idm_k8s_upgrade', defaultValue: enabled),
        booleanParam(name: 'Postcommit_idm_basic_perf', defaultValue: enabled),
        booleanParam(name: 'Postcommit_ig_k8s_postcommit', defaultValue: enabled) ,
        booleanParam(name: 'Postcommit_ig_k8s_upgrade', defaultValue: enabled),
        booleanParam(name: 'Postcommit_ig_basic_perf', defaultValue: enabled),
        booleanParam(name: 'Postcommit_platform_ui', defaultValue: enabled),
        booleanParam(name: 'Postcommit_set_images', defaultValue: enabled),
    ]
}

def getDefaultConfig(Random random, String stageName) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def randomNumber = random.nextInt(9999) + 10000 // 5 digit random number to compute to namespace
    def config = [
        STASH_PLATFORM_IMAGES_BRANCH        : commonModule.platformImagesRevision,
        STASH_FORGEOPS_BRANCH               : commonModule.GIT_COMMIT,
        STASH_LODESTAR_BRANCH               : params.Lodestar_ref != '' ? params.Lodestar_ref : commonModule.lodestarRevision,
        DEPLOYMENT_NAMESPACE                : cloud_config.spyglaasConfig()['DEPLOYMENT_NAMESPACE'] + '-' + randomNumber,
        REPORT_NAME_PREFIX                  : normalizedStageName,
        PIPELINE_NAME                       : 'Postcommit-Forgeops',
        DO_RECORD_RESULT                    : false,
        COMPONENTS_LODESTARBOX_IMAGE_TAG    : commonModule.lodestarRevision,
        COMPONENTS_LOCUST_IMAGE_TAG         : commonModule.lodestarRevision
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
    stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud(testName)

    runCommon(pipelineRun, stageName, stagesCloud) {
        withGKEPyrockNoStages(testConfig)
    }
}

def runPlatformUi(PipelineRunLegacyAdapter pipelineRun, Random random, String stageName, Map config) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def testConfig = getDefaultConfig(random, stageName) + config +
            [EXT_PLATFORM_IMAGES_BRANCH: commonModule.platformImagesRevision]
    def stagesCloud = [:]
    stagesCloud[normalizedStageName] = dashboard_utils.spyglaasStageCloud(normalizedStageName)

    def reportUrl = "${env.BUILD_URL}/${normalizedStageName}/"

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('gce-vm-lodestar-n1-standard-8') {
            stage(stageName) {
                try {
                    def uiFileContent = bitbucketUtils.readFileContent(
                            'cloud',
                            'platform-images',
                            commonModule.platformImagesRevision,
                            'ui.json').trim()
                    def uiTestRevision = readJSON(text: uiFileContent)['gitCommit']

                    dir("platform-ui") {
                        // Checkout Platform UI repository commit corresponding to the UI images commit promoted
                        localGitUtils.deepCloneBranch('ssh://git@stash.forgerock.org:7999/ui/platform-ui.git', 'master')
                        sh "git checkout ${uiTestRevision}"
                        uiTestsStage = load('jenkins-scripts/stages/ui-tests.groovy')
                    }

                    allStagesCloud[normalizedStageName] = stagesCloud[normalizedStageName]
                    allStagesCloud[normalizedStageName].numFailedTests = 0
                    allStagesCloud[normalizedStageName].reportUrl = reportUrl

                    def uiTestConfig = [
                            containerRunOptions : cloud_utils.getUiContainerRunOptions(testConfig),
                            deploymentNamespace : testConfig.DEPLOYMENT_NAMESPACE,
                    ]

                    uiTestsStage.runTests(uiTestConfig, normalizedStageName, normalizedStageName,
                            commonModule.lodestarRevision)
                } catch (Exception e) {
                    print(e.getMessage())
                    allStagesCloud[normalizedStageName].numFailedTests = 1
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
