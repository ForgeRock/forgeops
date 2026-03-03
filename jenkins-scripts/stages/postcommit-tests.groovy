/*
 * Copyright 2021-2026 Ping Identity Corporation. All Rights Reserved
 * 
 * This code is to be used exclusively in connection with Ping Identity 
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a 
 * binding license agreement with Ping Identity Corporation.
 */

// postcommit-tests.groovy

import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter

void runStage(PipelineRunLegacyAdapter pipelineRun) {
    try {
        // Define group of tests to execute on a GCE VM, we can't run all the tests at the same time
        // otherwise we have lot of timeout issues with the cluster
        // Each group below is executed on a GCE VM
        String[][] stageToCheckbox = [
                [
                        'Postcommit_pit1',
                        'Postcommit_perf_postcommit',
                        'Postcommit_perf_restore',
                        'Postcommit_am_k8s_postcommit',
                        'Postcommit_am_k8s_upgrade',
                        'Postcommit_ds_k8s_postcommit',
                        'Postcommit_ds_k8s_upgrade',
                        'Postcommit_ig_k8s_postcommit',
                        'Postcommit_set_images',
                ],
                    [
                        'Postcommit_guillotine_cli',
                        'Postcommit_guillotine_ds',
                        'Postcommit_guillotine_upgrade',
                        'Postcommit_guillotine_ig',
                        'Postcommit_guillotine_acceptance',
                        'Postcommit_guillotine_small_profile',
                        'Postcommit_guillotine_set_images',
                        'Postcommit_guillotine_misc',
                ],
        ]

        // To avoid issue we don't execute the group above at the same time, we wait 5 mins between each
        // Here we calculate the time to wait before executing a group and if a group is emtpy we don't wait
        Integer[] sleepTimesMinutes = new Integer[stageToCheckbox.length]
        int i = 0
        int sleep = 0
        for (String[] checkboxNames: stageToCheckbox) {
            if (checkboxNames.any { elem -> params[elem] }) {
                sleepTimesMinutes[i] = sleep
                sleep += 5
            }
            i++
        }

        parallel(
                'postcommit-set-0': {
                    runPostcommitInNode(0, sleepTimesMinutes) {
                        runPostcommitSet0(pipelineRun)
                    }
                },
                'postcommit-set-1': {
                    runPostcommitInNode(1, sleepTimesMinutes) {
                        runPostcommitSet1(pipelineRun)
                    }
                }
        )
    } catch (Exception exception) {
        println("Exception during parallel stage: ${exception}")
        throw exception
    }
}

def runPostcommitInNode(int stageNumber, Integer[] sleepTimeMinutes, Closure runPostcommit) {
    if (sleepTimeMinutes[stageNumber] != null) {
        sleep(time: sleepTimeMinutes[stageNumber], unit: 'MINUTES')

        node('gce-vm-forgeops-n2d-standard-32') {
            checkout scm
            sh "git checkout ${commonModule.GIT_COMMIT}"

            runPostcommit()
        }
    } else {
        println("No tests to execute in postcommit-set-${stageNumber}")
    }
}

def runPostcommitSet0(PipelineRunLegacyAdapter pipelineRun) {
    def parallelTestsMap = [:]

    // **************
    // DEV full tests
    // **************
    if (params.Postcommit_pit1) {
        parallelTestsMap.put('PIT1',
            {
                commonLodestarModule.runLodestar(pipelineRun, 'PIT1') { c -> cloud_tests.runCdmOrAicFuncPit1(c) }
            }
        )
    }

    if (params.Postcommit_perf_postcommit) {
        parallelTestsMap.put('Perf Postcommit',
            {
                commonLodestarModule.runLodestar(pipelineRun, 'Perf Postcommit') { c -> cloud_tests.runCdmPerfPostcommit(c) }
            }
        )
    }

    if (params.Postcommit_perf_restore) {
        parallelTestsMap.put('Perf Restore',
            {
                commonLodestarModule.runLodestar(pipelineRun, 'Perf Restore') { c -> cloud_tests.runCdmPerfPostcommit(c) }
            }
        )
    }

    // *************
    // DEV k8s tests
    // *************
    if (params.Postcommit_am_k8s_postcommit) {
        parallelTestsMap.put('AM K8s Postcommit',
            {
                commonLodestarModule.runLodestar(pipelineRun, 'AM K8s Postcommit') { c -> cloud_tests.runCdmFuncAmK8sPostcommit(c) }
            }
        )
    }
    if (params.Postcommit_am_k8s_upgrade) {
        parallelTestsMap.put('AM K8s Upgrade',
            {
                commonLodestarModule.runLodestar(pipelineRun, 'AM K8s Upgrade') { c -> cloud_tests.runCdmFuncAmK8sUpgrade(c) }
            }
        )
    }

    if (params.Postcommit_ds_k8s_postcommit) {
        parallelTestsMap.put('DS K8s Postcommit',
            {
                commonLodestarModule.runLodestar(pipelineRun, 'DS K8s Postcommit') { c -> cloud_tests.runCdmFuncDsK8sPostcommit(c) }
            }
        )
    }
    if (params.Postcommit_ds_k8s_upgrade) {
        println('yyyyy')
        parallelTestsMap.put('DS K8s Upgrade',
            {
                commonLodestarModule.runLodestar(pipelineRun, 'DS K8s Upgrade') { c -> cloud_tests.runCdmFuncDsK8sUpgrade(c) }
            }
        )
    }
    if (params.Postcommit_ig_k8s_postcommit) {
        parallelTestsMap.put('IG K8s Postcommit',
            {
                commonLodestarModule.runLodestar(pipelineRun, 'IG K8s Postcommit') { c -> cloud_tests.runCdmFuncIgK8sPostcommit(c) }
            }
        )
    }

    if (params.Postcommit_set_images) {
        parallelTestsMap.put('Set Images',
            {
                commonLodestarModule.runLodestar(pipelineRun, 'Set Images', [STASH_PLATFORM_IMAGES_REF: 'sustaining/8.0.x']) { c -> cloud_tests.runCdmFuncSetImages(c) }
            }
        )
    }

    parallel parallelTestsMap
}

def runPostcommitSet1(PipelineRunLegacyAdapter pipelineRun) {
    def parallelTestsMap = [:]

    // ****************
    // Guillotine tests
    // ****************


    if (params.Postcommit_guillotine_cli) {
        parallelTestsMap.put('Guillotine - Forgeops cli',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Forgeops Test Group', '--test-names Forgeops', '')
            }
        )
    }

    if (params.Postcommit_guillotine_ds) {
        parallelTestsMap.put('Guillotine - DS',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - DS', '--test-names Kustomize.DsBackup,Kustomize.DsBackupSnapshot,Kustomize.DsDebug', '')
            }
        )
    }

    if (params.Postcommit_guillotine_upgrade) {
        parallelTestsMap.put('Guillotine - Upgrade',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Upgrade', '--test-names Helm.UpgradeForgeops,Kustomize.UpgradePlatform74To75,Kustomize.UpgradeForgeops,Helm.BackwardsCompatibilityDev', '')
            }
        )
    }

    if (params.Postcommit_guillotine_ig) {
        parallelTestsMap.put('Guillotine - IG',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - IG', '--test-names Kustomize.SmokeIG,Helm.SmokeIG', '')
            }
        )
    }

    if (params.Postcommit_guillotine_acceptance) {
        parallelTestsMap.put('Guillotine - Acceptance',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Acceptance', '--test-names Kustomize.Acceptance,Helm.Acceptance,Helm.ChangeSizeDeployment', '')
            }
        )
    }

    if (params.Postcommit_guillotine_small_profile) {
        parallelTestsMap.put('Guillotine - Smoke - small profile',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Smoke - small profile', '--test-names Kustomize.SmallProfile', '')
            }
        )
    }

    if (params.Postcommit_guillotine_set_images) {
        parallelTestsMap.put('Guillotine - Set Images',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Set Images', '--test-names Kustomize.SetImages', '')
            }
        )
    }

    if (params.Postcommit_guillotine_misc) {
        parallelTestsMap.put('Guillotine - Misc',
            {
                commonModule.runGuillotine(pipelineRun, 'Guillotine - Misc', '--test-names Kustomize.ForgeopsInfo,', '')
            }
        )
    }

    parallel parallelTestsMap
}

return this
