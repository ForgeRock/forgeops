/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

void runStage(pipelineRun) {
    def parallelTestsMap = [
        Greenfield: { greenfieldTests.runStage(pipelineRun) },
        //Upgrade: { upgradeTests.runStage(pipelineRun) },
        PerfStack: { perfTests.runStage(pipelineRun, 'Perf Stack', 'stack', 'jenkins.yaml') },
        PerfAuthnSharedRepo: { perfTests.runStage(pipelineRun, 'Perf AuthN', 'authn_rest', 'jenkins.yaml') },
        PerfDSCrudShared: { perfTests.runStage(pipelineRun, 'Perf CRUD on simple managed users', 'simple_managed_users', 'jenkins.yaml') }
    ]

    parallel parallelTestsMap
}

return this