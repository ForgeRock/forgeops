/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import com.forgerock.pipeline.reporting.PipelineRun

void runStage(PipelineRun pipelineRun, String stageName, String scope, String deploymentName, String imageName) {

    pipelineRun.pushStageOutcome(commonModule.normalizeStageName(stageName), stageDisplayName: stageName) {
        node('google-cloud') {
            stage(stageName) {
                pipelineRun.updateStageStatusAsInProgress()
                def forgeopsPath = localGitUtils.checkoutForgeops()

                String upgradeDsVersion = commonModule.UPGRADE_TEST_BASE_DS_VERSION
                if (imageName == 'ds-empty') {
                    upgradeDsVersion = commonModule.UPGRADE_TEST_BASE_DSEMPTY_VERSION
                }

                dir('lodestar') {
                    def cfg = [
                        TESTS_SCOPE                     : scope,
                        DEPLOYMENT_NAME                 : deploymentName,
                        DS_IMAGE_NAME                   : imageName,
                        CLUSTER_NAMESPACE               : "upgrade-${imageName}",
                        CLUSTER_DOMAIN                  : 'pit-24-7.forgeops.com',
                        COMPONENTS_AMSTER_IMAGE_TAG     : commonModule.UPGRADE_TEST_BASE_AMSTER_VERSION,
                        COMPONENTS_AM_IMAGE_TAG         : commonModule.UPGRADE_TEST_BASE_AM_VERSION,
                        COMPONENTS_AM_IMAGE_UPGRADE_TAG : commonModule.getHelmChart('am').currentTag,
                        COMPONENTS_IDM_IMAGE_TAG        : commonModule.UPGRADE_TEST_BASE_IDM_VERSION,
                        COMPONENTS_IDM_IMAGE_UPGRADE_TAG: commonModule.getHelmChart('idm').currentTag,
                        COMPONENTS_CTSSTORE_IMAGE_TAG   : upgradeDsVersion,
                        COMPONENTS_CTSSTORE_IMAGE_REPOSITORY : "gcr.io/forgerock-io/${imageName}/pit1",
                        COMPONENTS_USERSTORE_IMAGE_TAG  : upgradeDsVersion,
                        COMPONENTS_USERSTORE_IMAGE_REPOSITORY : "gcr.io/forgerock-io/${imageName}/pit1",
                        COMPONENTS_USERSTORE_IMAGE_UPGRADE_TAG : commonModule.getHelmChart('ds').currentTag,
                        COMPONENTS_USERSTORE_IMAGE_UPGRADE_REPOSITORY : "gcr.io/forgerock-io/${imageName}/pit1",
                        // The image used for AM upgrade contains old layout
                        COMPONENTS_AM_UTILIMAGE_TAG     : '7.0.0-am-old-layout',
                        COMPONENTS_AM_AM_SECRETSDIR     : '/home/forgerock/openam/am',
                        COMPONENTS_AM_AM_KEYSTORESDIR   : '/home/forgerock/openam/am',
                        STASH_LODESTAR_BRANCH           : commonModule.LODESTAR_GIT_COMMIT,
                        EXT_FORGEOPS_BRANCH             : 'fraas-production',
                        EXT_FORGEOPS_UPGRADE_BRANCH     : commonModule.FORGEOPS_GIT_COMMIT,
                        EXT_FORGEOPSINIT_REPO           : 'https://github.com/ForgeRock/forgeops-init.git',
                        EXT_FORGEOPSINIT_BRANCH         : 'fraas-production'
                    ]

                    commonModule.determinePitOutcome("${env.BUILD_URL}/Allure_20Report_20PIT_5fUpgrade_5fWith_5f${imageName}_5fImage") {
                        withGKEPitNoStages(cfg)
                    }
                }
            }
        }
    }
}

return this
