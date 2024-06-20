/*
 * Copyright 2019-2024 Ping Identity Corporation. All Rights Reserved
 * 
 * This code is to be used exclusively in connection with Ping Identity 
 * Corporation software or services. Ping Identity Corporation only offers
 * such software or services to legal entities who have entered into a 
 * binding license agreement with Ping Identity Corporation.
 */

/*
 * Common configuration used by several stages of the ForgeOps pipeline.
 */
import com.forgerock.pipeline.reporting.PipelineRunLegacyAdapter
import com.forgerock.pipeline.stage.Status
import com.forgerock.pipeline.stage.Outcome
import com.forgerock.pipeline.stage.FailureOutcome

/**
 * Globally scoped git commit information
 */
SHORT_GIT_COMMIT = sh(script: 'git rev-parse --short=15 HEAD', returnStdout: true).trim()
GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
GIT_COMMITTER = sh(returnStdout: true, script: 'git show -s --pretty=%cn').trim()
GIT_MESSAGE = sh(returnStdout: true, script: 'git show -s --pretty=%s').trim()
GIT_COMMITTER_DATE = sh(returnStdout: true, script: 'git show -s --pretty=%cd --date=iso8601').trim()
GIT_BRANCH = env.JOB_NAME.replaceFirst(".*/([^/?]+).*", "\$1").replaceAll("%2F", "/")

def normalizeStageName(String stageName) {
    return stageName.toLowerCase().replaceAll('\\s', '-')
}

/** Default platform-images tag corresponding to this branch (or the PR target branch, if this is a PR build) */
String calculatePlatformImagesTag() {
    return "${calculatePlatformImagesBranch()}-ready-for-dev-pipelines"
}
DEFAULT_PLATFORM_IMAGES_TAG = calculatePlatformImagesTag()

String calculatePlatformImagesBranch() {
    def branchName = isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME
    if (branchName.startsWith('release/')) {
        def versionParts = (branchName - 'release/').tokenize('-')[0].tokenize('.')
        return "sustaining/${versionParts[0]}.${versionParts[1]}.x"
    } else {
        return 'master'
    }
}

/** Revision of platform-images repo used for k8s and platform integration/perf tests. */
platformImagesRevision = bitbucketUtils.getLatestCommitHash(
        'cloud',
        'platform-images',
        DEFAULT_PLATFORM_IMAGES_TAG)

/** Revision of Lodestar framework used for K8s and platform integration/perf tests. */
lodestarFileContent = bitbucketUtils.readFileContent(
        'cloud',
        'platform-images',
        platformImagesRevision,
        'lodestar.json').trim()
lodestarRevision = readJSON(text: lodestarFileContent)['gitCommit']

/** Does the branch support PIT tests */
boolean branchSupportsPitTests() {
    def supportedBranchPrefixes = [
            'master',
            'idcloud-',
            'release/',
            'sustaining/',
            'preview/',
    ]
    String branch = isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME
    return supportedBranchPrefixes.any { it -> branch.startsWith(it) }
}

/** Does the branch support PaaS releases */
// TODO Improve the code below to take into account new sustaining branches
// We should only promote version >= 7.1.0
// To be discussed with Bruno and Robin
boolean branchSupportsIDCloudReleases() {
    def branchName = isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME
    return branchName.equals('master') \
            || branchName.equals('feature/config') \
            || branchName.equals('release/7.1.0') \
            || branchName.startsWith('idcloud-') \
            || branchName.startsWith('sustaining/') \
            || branchName.startsWith('preview/')
}

void buildImage(String directoryName, String imageName, String arguments) {

}

def authenticateGke() {
    withCredentials([file(credentialsId: 'jenkins-guillotine-sa-key', variable: 'GC_KEY')]) {
        sh("gcloud auth activate-service-account --key-file=${env.GC_KEY} --project=engineering-devops")
    }
}

def authenticateEks() {
    withCredentials([file(credentialsId: 'guillotineAWSKeyCSV', variable: 'EKS_KEY')]) {
        sh("aws configure import --csv file://${env.EKS_KEY}")
    }
}

def runGuillotine(PipelineRunLegacyAdapter pipelineRun, stageName, providerName, options) {
    stage(stageName) {
        def normalizedStageName = normalizeStageName(stageName)
        withPipelineRun(pipelineRun, stageName, normalizedStageName) {
            // Create container to be able to use python3
            dockerUtils.insideGoogleCloudImage(dockerfilePath: 'docker/google-cloud', getDockerfile: true) {
                dir('guillotine') {

                    localGitUtils.deepCloneBranch('ssh://git@stash.forgerock.org:7999/cloud/guillotine.git', 'master')
                    def branchName = isPR() ? env.CHANGE_TARGET : env.BRANCH_NAME

                    if (providerName == 'GKE'){
                        authenticateGke()
                        // Configure environment to make Guillotine works on GKE
                        withCredentials([file(credentialsId: 'jenkins-guillotine-storage-gke-sa-key', variable: 'G_STORAGE_GKE_KEY')]) {
                            sh("./configure.py env --gke-only --gke-storage-sa ${env.G_STORAGE_GKE_KEY}")
                        }
                    }
                    else if (providerName == 'EKS'){
                        authenticateEks()
                        // Configure environment to make Guillotine works on EKS
                        sh("./configure.py env --eks-only")
                    }
                    else {
                        echo("FAILURE : unknown providerName `${providerName}`")
                        currentBuild.result = 'FAILURE'
                    }

                    // Configure Guillotine to run tests
                    sh("./configure.py runtime --forgeops-branch-name ${branchName} --set platform.platform-image-ref=${DEFAULT_PLATFORM_IMAGES_TAG} --forgeops-profile cdk ${options}")

                    try {
                        // Run the tests
                        sh("./run.py")
                        currentBuild.result = 'SUCCESS'
                    } catch (Exception exc) {
                        currentBuild.result = 'FAILURE'
                        println('Exception in main(): ' + exc.getMessage())
                        throw exc
                    } finally {
                        if (fileExists('reports/latest')) {
                            dir('tmp_dir') {
                                // Archive all folders and files out of the docker container
                                sh(script: "cp -r ../reports/latest/* .")
                                archiveArtifacts(artifacts: '**')
                                // Remove tmp folder (to save disk space) and publish html and logs in jenkins left side bar
                                sh(script: "rm -rf tmp")
                                publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true,
                                             reportDir   : '.', reportFiles: 'report.html',
                                             reportName  : "Guillotine Test Report ${normalizedStageName}",
                                             reportTitles: ''])
                            }
                        }
                        sh("./shared/scripts/jenkins_clean_namespaces.py")
                    }
                }
            }
        }
    }
}

def withPipelineRun(PipelineRunLegacyAdapter pipelineRun, String stageName, String normalizedStageName, Closure process) {
    // Warning :  reportUrl value must map the name defined in runGuillotine() : publishHTML.reportName
    def reportUrl = "${env.JOB_URL}/${env.BUILD_NUMBER}/Guillotine_20Test_20Report_20${normalizedStageName}"
    if (pipelineRun != null) {
        pipelineRun.pushStageOutcome(normalizedStageName, stageDisplayName: stageName) {
            try {
                process()
                return new Outcome(Status.SUCCESS, reportUrl)
            } catch (Exception e) {
                return new FailureOutcome(e, reportUrl)
            }
        }
    } else {
        process()
    }
}


return this
