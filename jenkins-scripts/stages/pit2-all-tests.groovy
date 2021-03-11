/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// pit2-all-tests.groovy

void runStage(pipelineRun) {
    def parallelTestsMap = [:]

    if (params.PIT2_Greenfield.toInteger() > 0) {
        parallelTestsMap.put('Greenfield', { greenfieldTests.runStage(pipelineRun) })
    }
    if (params.PIT2_Upgrade.toBoolean()) {
        parallelTestsMap.put('Upgrade', { upgradeTests.runStage(pipelineRun) })
    }
    if (env.getEnvironment().any { name, value -> name.startsWith('PIT2_Perf') && value.toBoolean() }) {
        parallelTestsMap.put('Perf', { perfTests.runStage(pipelineRun) })
    }
    if (params.PIT2_Platform_UI.toBoolean()) {
        parallelTestsMap += ['Platform UI': { platformUiTests.runStage(pipelineRun) }]
    }
    
    parallel parallelTestsMap
}

return this
