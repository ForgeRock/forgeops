/*
 * Copyright 2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// pit2-platform-ui-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status
import com.forgerock.pipeline.stage.Outcome
import com.forgerock.pipeline.stage.FailureOutcome

/**
 * Executes the e2e UI tests.
 *
 * This deploys the whole platform in k8s using lodestar with the UI images set to ones from the current commit.
 * The e2e tests are then run using a special docker image provided by cypress, the test framework that we use.
 * Reports are then generated via mochawesome and published to jenkins.
 */
void runStage(PipelineRunLegacyAdapter pipelineRun) {
    def stageName = 'PIT2 Platform UI'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def reportUrl = "${env.BUILD_URL}/${normalizedStageName}/"

    pipelineRun.pushStageOutcome([tags : ['PIT2'], stageDisplayName : stageName], normalizedStageName) {
        try {
            stage(stageName) {
                // TODO: To update to use 'pit2-platform-ui' once RELENG-1165 is done
                node('pit2-upgrade') {
                    def adminImageTag
                    def adminImageRepository
                    def endUserImageTag
                    def endUserImageRepository
                    def loginImageTag
                    def loginImageRepository

                    privateWorkspace {
                        checkout scm
                        sh "git checkout ${commonModule.FORGEOPS_GIT_COMMIT}"

                        // Admin UI Tag management
                        def yamlAdminFile = 'kustomize/base/admin-ui/deployment.yaml'
                        def adminImage = readYaml(file: yamlAdminFile).spec.template.spec.containers.image[0]
                        Collection<String> adminImageParts = adminImage.split(':')
                        adminImageRepository = adminImageParts.first()
                        adminImageTag = adminImageParts.last()

                        // End User UI Tag management
                        def yamlEndUserFile = 'kustomize/base/end-user-ui/deployment.yaml'
                        def endUserImage = readYaml(file: yamlEndUserFile).spec.template.spec.containers.image[0]
                        Collection<String> endUserImageParts = endUserImage.split(':')
                        endUserImageRepository = endUserImageParts.first()
                        endUserImageTag = endUserImageParts.last()

                        // Login UI Tag management
                        def yamlLoginFile = 'kustomize/base/login-ui/deployment.yaml'
                        def loginImage = readYaml(file: yamlLoginFile).spec.template.spec.containers.image[0]
                        Collection<String> loginImageParts = loginImage.split(':')
                        loginImageRepository = loginImageParts.first()
                        loginImageTag = loginImageParts.last()
                    }

                    def uiTestsConfig = [
                            TESTS_SCOPE                           : 'tests/k8s/postcommit/platform_ui',
                            CLUSTER_DOMAIN                        : 'pit-24-7.forgeops.com',
                            CLUSTER_NAMESPACE                     : 'platform-ui',
                            COMPONENTS_ADMINUI_IMAGE_TAG          : adminImageTag,
                            COMPONENTS_ADMINUI_IMAGE_REPOSITORY   : adminImageRepository,
                            COMPONENTS_ENDUSERUI_IMAGE_TAG        : endUserImageTag,
                            COMPONENTS_ENDUSERUI_IMAGE_REPOSITORY : endUserImageRepository,
                            COMPONENTS_LOGINUI_IMAGE_TAG          : loginImageTag,
                            COMPONENTS_LOGINUI_IMAGE_REPOSITORY   : loginImageRepository,
                            SKIP_TESTS                            : 'True', // Don't run any tests from lodestar, because it's only being used to deploy to k8s. Our own tests are run below.
                            SKIP_CLEANUP                          : 'True', // Defer cleanup of the K8S cluster, so it can be used by the e2e tests.
                            REPORT_NAME_PREFIX                    : normalizedStageName,
                            STASH_LODESTAR_BRANCH                 : commonModule.LODESTAR_GIT_COMMIT,
                            STASH_FORGEOPS_BRANCH                 : commonModule.FORGEOPS_GIT_COMMIT,
                    ]

                    dir("platform-ui") {
                        // Checkout Platform UI repository commit corresponding to the UI images commit promoted to Forgeops
                        localGitUtils.deepCloneBranch('ssh://git@stash.forgerock.org:7999/ui/platform-ui.git', 'master')
                        Collection<String> adminImageTagParts = adminImageTag.split('-')
                        def adminImagecommit = adminImageTagParts.last()
                        sh "git checkout ${adminImagecommit}"
                        uiTestsStage = load('jenkins-scripts/stages/ui-tests.groovy')
                    }

                    // The Platform UI repo needs to already be checked out in the platform-ui directory
                    // for this method call to work
                    uiTestsStage.runTests(uiTestsConfig, normalizedStageName, normalizedStageName)
                }
            }
        } catch(Exception e) {
            return new FailureOutcome(e, reportUrl)
        }

        return new Outcome(Status.SUCCESS, reportUrl)
    }
}

return this
