/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

void runStage(String stageName, String testName, String yamlFile) {
    node('perf-cloud') {
        stage(stageName) {
            def forgeopsPath = localGitUtils.checkoutForgeops()

            dir('lodestar') {
                def cfg = [
                    TEST_NAME            : testName,
                    JENKINS_YAML         : yamlFile,
                    NAMED_REPORT         : true,
                    STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
                    SKIP_FORGEOPS        : 'True',
                    EXT_FORGEOPS_PATH    : forgeopsPath
                ]

                withGKEPyrockNoStages(cfg)
            }
        }
    }
}

return this
