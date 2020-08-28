/*
 * Copyright 2019-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

void runStage(pipelineRun) {

    stage('Scale pit-24-7 cluster to 3 nodes') {
        node('google-cloud') {
            cloud_utils.authenticate_gcloud()
            cloud_utils.scaleClusterNodePool('pit-24-7', 'primary', 'us-west2', 3)
        }
    }

    def parallelTestsMap = [
        Greenfield: { greenfieldTests.runStage(pipelineRun) },
        Upgrade: { upgradeTests.runStage(pipelineRun) },
        Perf: { perfTests.runStage(pipelineRun) },
    ]

    parallel parallelTestsMap

    stage('Scale pit-24-7 cluster to 1 node') {
        node('google-cloud') {
            cloud_utils.authenticate_gcloud()
            cloud_utils.scaleClusterNodePool('pit-24-7', 'primary', 'us-west2', 1)
        }
    }
}

return this
