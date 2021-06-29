/*
 * Copyright 2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// lodestar-common.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

fraasProductionTag = 'fraas-production'

productLatestTag = '7.2.0-latest-postcommit'
productPostcommitStable = 'postcommit-stable'

allStagesCloud = [:]

boolean doRunPostcommitTests() {
    return !params.isEmpty() && params.any { name, value -> name.startsWith('Postcommit_') && value }
}

ArrayList postcommitMandatoryStages(boolean enabled) {
    return [
        booleanParam(name: 'Postcommit_pit1', defaultValue: enabled),
        booleanParam(name: 'Postcommit_perf_postcommit', defaultValue: enabled),
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
    ]
}

def getDefaultConfig(Random random, String stageName) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def randomNumber = random.nextInt(9999) + 10000 // 5 digit random number to compute to namespace
    return [STASH_LODESTAR_BRANCH   : commonModule.LODESTAR_GIT_COMMIT,
            STASH_FORGEOPS_BRANCH   : isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME,
            CLUSTER_NAMESPACE       : cloud_config.spyglaasConfig()['CLUSTER_NAMESPACE'] + '-' + randomNumber,
            REPORT_NAME_PREFIX      : normalizedStageName,
            PIPELINE_NAME           : 'Postcommit-Lodestar',
            DO_RECORD_RESULT        : false]
}

def runCommon(PipelineRunLegacyAdapter pipelineRun, String stageName, Map stagesCloud, Closure process) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('lodestar-cloud') {
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

def getLodestarDockerImagesTag() {
    return [COMPONENTS_LODESTARBOX_IMAGE_TAG    : commonModule.LODESTAR_GIT_COMMIT,
            COMPONENTS_LOCUST_IMAGE_TAG         : commonModule.LODESTAR_GIT_COMMIT]
}

def runSpyglaas(PipelineRunLegacyAdapter pipelineRun, Random random, String stageName, Map config) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def testConfig = getLodestarDockerImagesTag() + getDefaultConfig(random, stageName) + config
    def stagesCloud = [:]
    stagesCloud[normalizedStageName] = dashboard_utils.spyglaasStageCloud(normalizedStageName)

    runCommon(pipelineRun, stageName, stagesCloud) {
        withGKESpyglaasNoStages(testConfig)
    }
}

def runPyrock(PipelineRunLegacyAdapter pipelineRun, Random random, String stageName, Map config) {
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def testConfig = getLodestarDockerImagesTag() + getDefaultConfig(random, stageName) +
            [DO_RECORD_RESULT   : false,
             REPORT_NAME_PREFIX : normalizedStageName,
             PIPELINE_NAME      : 'LODESTAR_POSTCOMMIT'] + config
    def stagesCloud = [:]
    def testName = cloud_utils.pyrockGetTestName(testConfig)
    stagesCloud[normalizedStageName] = dashboard_utils.pyrockStageCloud(testName)

    runCommon(pipelineRun, stageName, stagesCloud) {
        withGKEPyrockNoStages(testConfig)
    }
}

return this
