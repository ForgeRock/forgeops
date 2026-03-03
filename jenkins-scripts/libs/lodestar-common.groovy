/*
 * Copyright 2021-2026 Ping Identity Corporation. All Rights Reserved
 * 
 * This code is to be used exclusively in connection with Ping Identity 
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a 
 * binding license agreement with Ping Identity Corporation.
 */

// lodestar-common.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

boolean doRunPostcommitTests() {
    return !params.isEmpty() && params.any { name, value -> name.startsWith('Postcommit_') && value }
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
        booleanParam(name: 'Postcommit_ig_k8s_postcommit', defaultValue: enabled),
        booleanParam(name: 'Postcommit_set_images', defaultValue: enabled),
        booleanParam(name: 'Postcommit_guillotine_cli', defaultValue: enabled),
        booleanParam(name: 'Postcommit_guillotine_ds', defaultValue: enabled),
        booleanParam(name: 'Postcommit_guillotine_upgrade', defaultValue: enabled),
        booleanParam(name: 'Postcommit_guillotine_ig', defaultValue: enabled),
        booleanParam(name: 'Postcommit_guillotine_acceptance', defaultValue: enabled),
        booleanParam(name: 'Postcommit_guillotine_small_profile', defaultValue: enabled),
        booleanParam(name: 'Postcommit_guillotine_set_images', defaultValue: enabled),
        booleanParam(name: 'Postcommit_guillotine_misc', defaultValue: enabled),
    ]
}

def runLodestar(PipelineRunLegacyAdapter pipelineRun, String stageName, Map config = [:], Closure<Map> process) {
    String normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    String clusterName = cloud_utils.computeClusterName("forgeops-${normalizedStageName}")

    Map testConfig = [
        STASH_PLATFORM_IMAGES_REF   : commonModule.platformImagesRevision,
        STASH_FORGEOPS_REF          : commonModule.GIT_COMMIT,
        STASH_LODESTAR_REF          : commonModule.lodestarRevision,
        PIPELINE_RUN                : pipelineRun,
        GITHUB_COMMIT               : commonModule.githubCommit,
        CLOUD_REPORT_LINE_NAME      : normalizedStageName,
        DEPLOYMENT_NAMESPACE        : cloud_utils.computeNamespaceName("${normalizedStageName}-ns"),
        SHORT_LIVED_CLUSTER_NAME    : clusterName,
        SHORT_LIVED_CLUSTER_REGION  : cloud_constants.FORGEOPS_PIPELINE_REGION,
        REPORT_NAME_PREFIX          : normalizedStageName,
        DO_RECORD_RESULT            : false,
        SLACK_CHANNEL               : "",
    ] + config

    process(testConfig)
}

return this
