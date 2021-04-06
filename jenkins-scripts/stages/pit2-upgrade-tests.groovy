/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// pit2-upgrade-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun) {

    def stageName = 'PIT2 Upgrade'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)

    pipelineRun.pushStageOutcome([tags : ['PIT2'], stageDisplayName : stageName], normalizedStageName) {
        node('pit2-upgrade') {
            stage(stageName) {
                dir('lodestar') {
                    def stagesCloud = [:]
                    stagesCloud[normalizedStageName] = dashboard_utils.spyglaasStageCloud(normalizedStageName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[normalizedStageName]) {
                        def config = [
                                TESTS_SCOPE                                     : 'tests/pit1',
                                UPGRADE_FIRST                                   : true,
                                CLUSTER_DOMAIN                                  : 'pit-24-7.forgeops.com',
                                CLUSTER_NAMESPACE                               : 'upgrade',
                                COMPONENTS_AM_IMAGE_UPGRADE_TAG                 : commonModule.getCurrentTag('am'),
                                COMPONENTS_AM_IMAGE_UPGRADE_REPOSITORY          : 'gcr.io/forgerock-io/am-base/pit1',
                                COMPONENTS_IDM_IMAGE_UPGRADE_TAG                : commonModule.getCurrentTag('idm'),
                                COMPONENTS_IDM_IMAGE_UPGRADE_REPOSITORY         : 'gcr.io/forgerock-io/idm/pit1',
                                COMPONENTS_IG_IMAGE_UPGRADE_TAG                 : commonModule.getCurrentTag('ig'),
                                COMPONENTS_IG_IMAGE_UPGRADE_REPOSITORY          : 'gcr.io/forgerock-io/ig/pit1',
                                COMPONENTS_DSIDREPO_IMAGE_UPGRADE_TAG           : commonModule.getCurrentTag('ds-idrepo'),
                                COMPONENTS_DSIDREPO_IMAGE_UPGRADE_REPOSITORY    : 'gcr.io/forgerock-io/ds/pit1',
                                COMPONENTS_DSCTS_IMAGE_UPGRADE_TAG              : commonModule.getCurrentTag('ds-cts'),
                                COMPONENTS_DSCTS_IMAGE_UPGRADE_REPOSITORY       : 'gcr.io/forgerock-io/ds/pit1',
                                STASH_LODESTAR_BRANCH                           : commonModule.LODESTAR_GIT_COMMIT,
                                STASH_FORGEOPS_BRANCH                           : 'fraas-production',
                                REPORT_NAME_PREFIX                              : normalizedStageName,
                                TIMEOUT                                         : '2',
                                TIMEOUT_UNIT                                    : 'HOURS'
                        ]

                        withGKESpyglaasNoStages(config)
                    }

                    return dashboard_utils.finalLodestarOutcome(stagesCloud, stageName)
                }
            }
        }
    }
}

return this
