/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

void runStage() {
    def parallelTestsMap = [
        Greenfield: { greenfieldTests.runStage() },
        Upgrade: { upgradeTests.runStage('Upgrade', 'tests/upgrade', 'ds-shared-repo') },
        PerfStack: { perfTests.runStage('Perf Stack', 'stack', 'jenkins.yaml') },
        PerfAuthnSharedRepo: { perfTests.runStage('AuthN with DS shared repo', 'authn_rest', 'jenkins-dssr.yaml') },
        PerfDSCrudShared: { perfTests.runStage('CRUD on simple managed users with DS shared repo', 'simple_managed_users_ds_shared_repo', 'jenkins.yaml') }
    ]
    
    parallel parallelTestsMap
}

return this