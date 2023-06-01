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
            sh("./configure.py env --gke-only")
            sh("./configure.py runtime --forgeops-branch-name ${branchName} --keywords FUNCTIONAL")
            sh("./run.py")
        }
    }
}

return this
