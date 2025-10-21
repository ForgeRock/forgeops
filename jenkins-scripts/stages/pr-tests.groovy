/*
 * Copyright 2021-2025 Ping Identity Corporation. All Rights Reserved
 * 
 * This code is to be used exclusively in connection with Ping Identity 
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a 
 * binding license agreement with Ping Identity Corporation.
 */

// pr-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun, Random random) {
    def parallelTestsMap = [:]

    parallelTestsMap.put('PIT1',
        {
            commonLodestarModule.runSpyglaas(pipelineRun, random, 'Pit1',
                [
                    TESTS_SCOPE: 'tests/pit1',
                ]
            )
        }
    )
    parallelTestsMap.put('Perf postcommit',
        {
            commonLodestarModule.runPyrock(pipelineRun, random, 'Perf Postcommit',
                [
                    TEST_NAME      : 'postcommit',
                    CONFIGFILE_NAME: 'conf-closed.yaml',
                    PROFILE_NAME   : 'small',
                ]
            )
        }
    )
    parallelTestsMap.put('Guillotine',
        {
            commonModule.runGuillotine(null, 'functional', 'GKE', '--keywords "PULL_REQUEST PLATFORM_IMAGE_REF"', '')
        }
    )

    parallel parallelTestsMap
}

return this
