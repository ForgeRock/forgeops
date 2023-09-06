/*
 * Copyright 2023 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// functional-tests.groovy
  def authenticateGcloud() {
    withCredentials([file(credentialsId: 'jenkins-guillotine-sa-key', variable: 'GC_KEY')]) {
        sh("gcloud auth activate-service-account --key-file=${env.GC_KEY} --project=engineering-devops")
    }
}

void runStage() {
    stage('Functional Tests')

    // Create container to be able to use python3
    dockerUtils.insideGoogleCloudImage(dockerfilePath: 'docker/google-cloud', getDockerfile: true) {
        dir('guillotine') {

            authenticateGcloud()

            localGitUtils.deepCloneBranch('ssh://git@stash.forgerock.org:7999/cloud/guillotine.git', 'master')
            def branchName = isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME
            // Configure environment to make Guillotine works on GKE
            sh("./configure.py env --gke-only")
            // Configure Guillotine to run functional tests (all test suites with FUNCTIONAL keyword)
            sh("./configure.py runtime --forgeops-branch-name ${branchName} --keywords FUNCTIONAL")
            try {
                // Run the tests
                sh("./run.py")
                currentBuild.result = 'SUCCESS'
            } catch (Exception exc) {
                currentBuild.result = 'FAILURE'
                println('Exception in main(): ' + exc.getMessage())
            } finally {
                if (fileExists('reports/latest')) {
                    dir('tmp_dir'){
                        // Archive all folders and files out of the docker container
                        sh(script:"cp -r ../reports/latest/* .")
                        archiveArtifacts(artifacts: '**')
                        // Remove tmp folder (to save disk space) and publish html and logs in jenkins left side bar
                        sh(script:"rm -rf tmp")
                        publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true,
                                     reportDir   : '.', reportFiles: 'report.html',
                                     reportName  : "Guillotine Test Report",
                                     reportTitles: ''])
                    }
                }
            }
        }
    }
}

return this
