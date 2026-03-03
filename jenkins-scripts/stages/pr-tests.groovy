/*
 * Copyright 2021-2026 Ping Identity Corporation. All Rights Reserved
 * 
 * This code is to be used exclusively in connection with Ping Identity 
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a 
 * binding license agreement with Ping Identity Corporation.
 */

// pr-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun) {
    def parallelTestsMap = [:]

    parallelTestsMap.put('PIT1',
        {
            commonLodestarModule.runLodestar(pipelineRun, 'PIT1') { c -> cloud_tests.runCdmOrAicFuncPit1(c) }
        }
    )

    parallelTestsMap.put('Perf postcommit',
        {
            commonLodestarModule.runLodestar(pipelineRun, 'Perf Postcommit') { c -> cloud_tests.runCdmPerfPostcommit(c) }
        }
    )

    parallelTestsMap.put('AM K8s Postcommit',
        {
            commonLodestarModule.runLodestar(pipelineRun, 'AM K8s Postcommit') { c -> cloud_tests.runCdmFuncAmK8sPostcommit(c) }
        }
    )

    parallelTestsMap.put('Guillotine - Forgeops cli',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Forgeops Test Group', '--test-names Forgeops', '')
            }
    )

    parallelTestsMap.put('Guillotine - DS',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - DS', '--test-names Kustomize.DsBackup,Kustomize.DsBackupSnapshot,Kustomize.DsDebug', '')
            }
    )

    parallelTestsMap.put('Guillotine - Upgrade',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Upgrade', '--test-names Helm.UpgradeForgeops,Kustomize.UpgradePlatform74To75,Kustomize.UpgradeForgeops,Helm.BackwardsCompatibilityDev', '')
            }
    )

    parallelTestsMap.put('Guillotine - IG',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - IG', '--test-names Kustomize.SmokeIG,Helm.SmokeIG', '')
            }
    )

    parallelTestsMap.put('Guillotine - Acceptance',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Acceptance', '--test-names Kustomize.Acceptance,Helm.Acceptance,Helm.ChangeSizeDeployment', '')
            }
    )

    parallelTestsMap.put('Guillotine - Smoke - small profile',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Smoke - small profile', '--test-names Kustomize.SmallProfile', '')
            }
    )

    parallelTestsMap.put('Guillotine - Set Images',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Set Images', '--test-names Kustomize.SetImages', '')
            }
    )

    parallelTestsMap.put('Guillotine - Misc',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Misc', '--test-names Kustomize.ForgeopsInfo,', '')
        }
    )

    parallel parallelTestsMap
}

return this
