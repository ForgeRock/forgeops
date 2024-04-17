/*
 * Copyright 2021-2024 Ping Identity Corporation. All Rights Reserved
 * 
 * This code is to be used exclusively in connection with Ping Identity 
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a 
 * binding license agreement with Ping Identity Corporation.
 */

// pr-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun, Random random) {
    return commonLodestarModule.runSpyglaas(pipelineRun, random, 'Deploymnent Only',
            [TESTS_SCOPE    : 'tests/deployment_only'])
}

return this
