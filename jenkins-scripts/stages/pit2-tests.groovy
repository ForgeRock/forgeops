/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

void runStage(pipelineRun) {
    def parallelTestsMap = [
        Greenfield: { greenfieldTests.runStage(pipelineRun, 'Greenfield') },
        Upgrade: { upgradeTests.runStage(pipelineRun, 'Upgrade', 'tests/upgrade', 'ds-shared-repo') },
        PerfStack: { perfTests.runStage(pipelineRun, 'Perf Stack', 'stack', 'jenkins.yaml') },
        PerfAuthnSharedRepo: { perfTests.runStage(pipelineRun, 'AuthN with DS shared repo', 'authn_rest', 'jenkins-dssr.yaml') },
        PerfDSCrudShared: { perfTests.runStage(pipelineRun, 'CRUD on simple managed users with DS shared repo', 'simple_managed_users_ds_shared_repo', 'jenkins.yaml') }
    ]
    
    parallel parallelTestsMap
}

return this