/*
 * Copyright 2021-2024 Ping Identity Corporation. All Rights Reserved
 * 
 * This code is to be used exclusively in connection with Ping Identity 
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a 
 * binding license agreement with Ping Identity Corporation.
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

SUMMARY_REPORT_NAME = 'SummaryReport'

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
        booleanParam(name: 'Postcommit_fo_acceptance', defaultValue: enabled),
        booleanParam(name: 'Postcommit_fo_smoke_small', defaultValue: enabled),
        booleanParam(name: 'Postcommit_fo_set_images', defaultValue: enabled),
        booleanParam(name: 'Postcommit_fo_dsbackup', defaultValue: enabled),
        booleanParam(name: 'Postcommit_fo_am_only', defaultValue: false),
        booleanParam(name: 'Postcommit_fo_idm_only', defaultValue: false),
        booleanParam(name: 'Postcommit_fo_ig_only', defaultValue: false),
        booleanParam(name: 'Postcommit_fo_ds_only', defaultValue: false),
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
    deploymentConfig += [SKIP_TESTS: true]
    deploymentConfig += [SKIP_CLEANUP: true]

    def testReportNamePrefix = testConfig.REPORT_NAME_PREFIX
    def testStageName = dashboard_utils.normalizeStageName(testReportNamePrefix)
    stagesCloud[testStageName] = dashboard_utils.spyglaasStageCloud(testStageName)
    testConfig += [SKIP_DEPLOY: true]
    testConfig += [DEPLOYMENT_UPGRADE_FIRST: true]

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
            [EXT_PLATFORM_IMAGES_REF: commonModule.platformImagesRevision,
             EXT_FORGEOPS_REF       : commonModule.GIT_COMMIT]
    def stagesCloud = [:]
    stagesCloud[normalizedStageName] = dashboard_utils.spyglaasStageCloud(normalizedStageName)

    def reportUrl = "${env.BUILD_URL}/${normalizedStageName}/"

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        def branchName = isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME
        if (branchName.startsWith('sustaining/') || branchName.startsWith('release/')) {
            // Skip the UI tests when running on sustaining and release branches
            return Status.SKIPPED.asOutcome()
        }

        node('gce-vm-forgeops-n2d-standard-8') {
            stage(stageName) {
                try {
                    platformUI.runPlatformUI(commonModule.lodestarRevision, commonModule.platformImagesRevision,
                            testConfig, normalizedStageName, commonModule.calculatePlatformImagesBranch())

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

def generateSummaryTestReport() {
    privateWorkspace {
        def stageName = SUMMARY_REPORT_NAME
        dashboard_utils.createAndPublishSummaryReport(
                allStagesCloud, stageName, '', false, stageName, "${stageName}.html")
    }
}

return this
