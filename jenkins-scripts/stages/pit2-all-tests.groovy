/*
 * Copyright 2019-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

void runStage(pipelineRun) {
    def parallelTestsMap = []

    if (params.PIT2_Greenfield.toInteger() > 0) {
        parallelTestsMap += ['Greenfield': { greenfieldTests.runStage(pipelineRun) }]
    }
    if (params.PIT2_Upgrade.toBoolean()) {
        parallelTestsMap += ['Upgrade': { greenfieldTests.runStage(pipelineRun) }]
    }
    if (env.getEnvironment().any { name, value -> name.startsWith('PIT2_Perf') && value.toBoolean() }) {
        parallelTestsMap += ['Perf': { greenfieldTests.runStage(pipelineRun) }]
    }

    parallel parallelTestsMap
}

return this
