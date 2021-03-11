/*
 * Copyright 2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// pit2-platform-ui-tests.groovy

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
    def stageName = 'Platform UI Tests'
    def normalizedStageName = dashboard_utils.normalizeStageName(stageName)
    def reportUrl = ''
    def reportName = 'E2E Test Report'

    pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
        try {
            stage(stageName) {
                node('google-cloud') {
                    def forgeopsPath = localGitUtils.checkoutForgeops()

                    // Admin UI Tag management
                    def yamlAdminFile = 'kustomize/base/admin-ui/deployment.yaml'
                    def adminImage = readYaml(file: yamlAdminFile).spec.template.spec.containers.image[0]
                    Collection<String> adminImageParts = adminImage.split(':')
                    String adminImageRepository = adminImage.first()
                    String adminImageTag = adminImage.last()

                    // End User UI Tag management
                    def yamlEndUserFile = 'kustomize/base/end-user-ui/deployment.yaml'
                    def endUserImage = readYaml(file: yamlEndUserFile).spec.template.spec.containers.image[0]
                    Collection<String> endUserImageParts = endUserImage.split(':')
                    String endUserImageRepository = endUserImageParts.first()
                    String endUserImageTag = endUserImageParts.last()

                    // Login UI Tag management
                    def yamlLoginFile = 'kustomize/base/login-ui/deployment.yaml'
                    def loginImage = readYaml(file: yamlLoginFile).spec.template.spec.containers.image[0]
                    Collection<String> loginImageParts = loginImage.split(':')
                    String loginImageRepository = loginImageParts.first()
                    String loginImageTag = loginImageParts.last()

                    def config = [
                            TESTS_SCOPE                           : 'tests/k8s/postcommit/platform_ui',
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
                            EXT_FORGEOPS_PATH                     : forgeopsPath,
                    ]

                    try {
                        dir('lodestar') {
                            dashboard_utils.determineUnitOutcome(dashboard_utils.spyglaasStageCloud(normalizedStageName)) {
                                withGKESpyglaasNoStages(config)
                            }
                        }

                        def namespace = config.CLUSTER_NAMESPACE

                        dir('platform-ui') {
                            localGitUtils.shallowCloneBranch('ssh://git@stash.forgerock.org:7999/ui/platform-ui.git', env.BRANCH_NAME)
                            sh "docker build --iidfile .iid -f e2e/Dockerfile ."

                            try {
                                withEnv(["KUBERNETES_NAMESPACE=${namespace}"]) {
                                    sh "./e2e/passwords.sh docker run " +
                                            "--cidfile .cid " +
                                            "--ipc host " +
                                            "-e VUE_APP_AM_URL=https://${namespace}.iam.pit-cluster.forgeops.com/am " +
                                            "-e VUE_APP_AM_ADMIN_URL=https://${namespace}.iam.pit-cluster.forgeops.com/am/ui-admin " +
                                            "-e VUE_APP_IDM_URL=https://${namespace}.iam.pit-cluster.forgeops.com/openidm " +
                                            "-e VUE_APP_IDM_ADMIN_URL=https://${namespace}.iam.pit-cluster.forgeops.com/admin " +
                                            "-e VUE_APP_ENDUSER_URL=https://${namespace}.iam.pit-cluster.forgeops.com/enduser " +
                                            "-e CYPRESS_AM_USERNAME " +
                                            "-e CYPRESS_IDM_USERNAME " +
                                            "-e CYPRESS_AM_PASSWORD " +
                                            "-e CYPRESS_IDM_PASSWORD " +
                                            "-e CYPRESS_ACCESS_TOKEN " +
                                            "-e CYPRESS_FQDN " +
                                            "-e CYPRESS_BASE_URL " +
                                            "\$(cat .iid)"
                                }
                            } finally {
                                sh "docker cp \$(cat .cid):/workspace container_workspace"
                                publishHTML(target: [
                                        allowMissing         : false,
                                        alwaysLinkToLastBuild: false,
                                        keepAll              : true,
                                        reportDir            : 'container_workspace/mochawesome-report',
                                        reportFiles          : 'mochawesome-report.html',
                                        reportName           : reportName
                                ])
                                reportUrl = "${env.BUILD_URL}/${reportName.replace(" ", "_20")}"
                                archiveArtifacts(artifacts: 'container_workspace/packages/*/e2e/screenshots/**/*', allowEmptyArchive: true)
                                archiveArtifacts(artifacts: 'container_workspace/packages/*/e2e/videos/**/*', allowEmptyArchive: true)
                            }
                        }
                    } finally {
                        // Cleanup the K8S deployment. This was skipped during withGKESpyglaasNoStages so the deployment could be used by the e2e tests.
                        withEnv(cloud_utils.setEnvironment(config)) {
                            dir('lodestar') {
                                sh("./cleanup.py -n ${namespace}")
                            }
                        }
                    }
                }
            }
        } catch(Exception e) {
            return new FailureOutcome(e, reportUrl)
        }

        return new Outcome(Status.SUCCESS, reportUrl)
    }
}

return this
