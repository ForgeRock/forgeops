/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

void runStage(String stageName, String scope, String sampleName) {
    node('google-cloud') {
        stage(stageName) {
            def forgeopsPath = localGitUtils.checkoutForgeops()

            dir('lodestar') {
                def cfg = [
                        TESTS_SCOPE          : scope,
                        SAMPLE_NAME          : sampleName,
                        STASH_LODESTAR_BRANCH: commonModule.LODESTAR_GIT_COMMIT,
                        SKIP_FORGEOPS        : 'True',
                        EXT_FORGEOPS_PATH    : forgeopsPath
                ]

                withGKEPitNoStages(cfg)
            }
        }
    }
}

return this