/*
 * Copyright 2019-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun) {

    def stageName = 'PIT2 Binary Upgrade'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def fraasTag = 'fraas-production'

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        node('pit2-upgrade') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()

                dir('lodestar') {
                    def stagesCloud = [:]

                    def initialSubStageName = 'binary_upgrade'

                    def config_common = [
                        CLUSTER_DOMAIN                                  : 'pit-24-7.forgeops.com',
                        CLUSTER_NAMESPACE                               : initialSubStageName,
                        COMPONENTS_AMSTER_IMAGE_TAG                     : fraasTag,
                        COMPONENTS_AM_IMAGE_TAG                         : fraasTag,
                        COMPONENTS_AM_IMAGE_UPGRADE_TAG                 : commonModule.getCurrentTag('am'),
                        COMPONENTS_AM_IMAGE_UPGRADE_REPOSITORY          : 'gcr.io/forgerock-io/am-base/pit1',
                        COMPONENTS_IDM_IMAGE_TAG                        : fraasTag,
                        COMPONENTS_IDM_IMAGE_UPGRADE_TAG                : commonModule.getCurrentTag('idm'),
                        COMPONENTS_IDM_IMAGE_UPGRADE_REPOSITORY         : 'gcr.io/forgerock-io/idm/pit1',
                        COMPONENTS_IG_IMAGE_TAG                         : fraasTag,
                        COMPONENTS_IG_IMAGE_UPGRADE_TAG                 : commonModule.getCurrentTag('ig'),
                        COMPONENTS_IG_IMAGE_UPGRADE_REPOSITORY          : 'gcr.io/forgerock-io/ig/pit1',
                        COMPONENTS_DSIDREPO_IMAGE_TAG                   : fraasTag,
                        COMPONENTS_DSIDREPO_IMAGE_UPGRADE_TAG           : commonModule.getCurrentTag('ds-idrepo'),
                        COMPONENTS_DSIDREPO_IMAGE_UPGRADE_REPOSITORY    : 'gcr.io/forgerock-io/ds/pit1',
                        COMPONENTS_DSCTS_IMAGE_TAG                      : fraasTag,
                        COMPONENTS_DSCTS_IMAGE_UPGRADE_TAG              : commonModule.getCurrentTag('ds-cts'),
                        COMPONENTS_DSCTS_IMAGE_UPGRADE_REPOSITORY       : 'gcr.io/forgerock-io/ds/pit1',
                        STASH_LODESTAR_BRANCH                           : commonModule.LODESTAR_GIT_COMMIT,
                        STASH_FORGEOPS_BRANCH                           : 'fraas-production',
                    ]

                    // Binary upgrade tests
                    stagesCloud[initialSubStageName] = dashboard_utils.spyglaasStageCloud(initialSubStageName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[initialSubStageName]) {
                        def config = config_common.clone()
                        config += [
                            TESTS_SCOPE                                  : 'tests/pit2/upgrade',
                            SKIP_CLEANUP                                 : true,
                            REPORT_NAME_PREFIX                           : initialSubStageName,
                        ]

                        withGKESpyglaasNoStages(config)
                    }

                    // pit1 tests after binary upgrade tests
                    subStageName = 'pit1_after_binary_upgrade'
                    stagesCloud[subStageName] = dashboard_utils.spyglaasStageCloud(subStageName)

                    dashboard_utils.determineUnitOutcome(stagesCloud[subStageName]) {
                        def config = config_common.clone()
                        config += [
                            TESTS_SCOPE                                  : 'tests/pit1',
                            SKIP_DEPLOY                                  : true,
                            REPORT_NAME_PREFIX                           : subStageName,
                        ]

                        withGKESpyglaasNoStages(config)
                    }

                    summaryReportGen.createAndPublishSummaryReport(stagesCloud, stageName, '', false,
                        normalizedStageName, "${normalizedStageName}.html")
                    return dashboard_utils.determineLodestarOutcome(stagesCloud,
                        "${env.BUILD_URL}/${normalizedStageName}/")
                }
            }
        }
    }
}

return this
