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

// TODO GitHub migration: remove ternary operator when platform-images GitHub migration is complete
githubRepository = scmUtils.isGitHubRepository() \
        ? githubUtils.organization(scmUtils.getRepositoryOwnerName(),
        githubUtils.githubAppCredentialsFromUrl(scmUtils.getRepoUrl()))
        .repository(scmUtils.getRepoName())
        : null
githubCommit = scmUtils.isGitHubRepository()
        ? githubRepository.commit(GIT_COMMIT)
        : null

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

/** Does the branch support PIT tests */
boolean branchSupportsPitTests() {
    def supportedBranchPrefixes = [
            'main',
            'dev',
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
    return branchName.equals('dev') \
            || branchName.equals('feature/config') \
            || branchName.equals('release/') \
            || branchName.startsWith('idcloud-') \
            || branchName.startsWith('sustaining/') \
            || branchName.startsWith('preview/')
}

/** Revision of platform-images repo used for k8s and platform integration/perf tests. */
// TODO GitHub migration remove ternary to only use githubUtils when GitHub migration is complete
platformImagesRevision = scmUtils.isGitHubRepository(env.PLATFORM_IMAGES_REPOSITORY_URL)\
                                        ? githubUtils.organization(scmUtils.getRepositoryOwnerName(env.PLATFORM_IMAGES_REPOSITORY_URL),
                                                                   githubUtils.githubAppCredentialsFromUrl(env.PLATFORM_IMAGES_REPOSITORY_URL))
                                                     .repository(scmUtils.getRepoName(env.PLATFORM_IMAGES_REPOSITORY_URL))
                                                     .branch(DEFAULT_PLATFORM_IMAGES_TAG)
                                                     .lastCommitHash()
                                                     .value()
                                        : bitbucketUtils.getLatestCommitHash(scmUtils.getRepositoryOwnerName(env.PLATFORM_IMAGES_REPOSITORY_URL),
                                                                             scmUtils.getRepoName(env.PLATFORM_IMAGES_REPOSITORY_URL),
                                                                             DEFAULT_PLATFORM_IMAGES_TAG)
                                                        .trim()

/** Revision of Lodestar framework used for K8s and platform integration/perf tests. */
// TODO GitHub migration remove ternary to only use githubUtils when GitHub migration is complete
lodestarRevision = readJSON(text: (scmUtils.isGitHubRepository(env.PLATFORM_IMAGES_REPOSITORY_URL)\
                                        ? githubUtils.organization(scmUtils.getRepositoryOwnerName(env.PLATFORM_IMAGES_REPOSITORY_URL),
                                                                   githubUtils.githubAppCredentialsFromUrl(env.PLATFORM_IMAGES_REPOSITORY_URL))
                                                     .repository(scmUtils.getRepoName(env.PLATFORM_IMAGES_REPOSITORY_URL))
                                                     .readFileContent('lodestar.json', platformImagesRevision)
                                                     .trim()
                                        : bitbucketUtils.readFileContent(scmUtils.getRepositoryOwnerName(env.PLATFORM_IMAGES_REPOSITORY_URL),
                                                                        scmUtils.getRepoName(env.PLATFORM_IMAGES_REPOSITORY_URL),
                                                                        platformImagesRevision,
                                                                        'lodestar.json')
                                                         .trim())
)['gitCommit']


def authenticateGke() {
    withCredentials([file(credentialsId: 'jenkins-guillotine-sa-key', variable: 'GC_KEY')]) {
        sh("gcloud auth activate-service-account --key-file=${env.GC_KEY} --project=engineering-devops")
    }
}


def runGuillotine(PipelineRunLegacyAdapter pipelineRun, String stageName, String providerName, String options, String platformImageRef='') {
    stage(stageName) {
        def normalizedStageName = normalizeStageName(stageName)
        withPipelineRun(pipelineRun, stageName, normalizedStageName) {
            // Create container to be able to use python3
            dockerUtils.insideGoogleCloudImage(dockerfilePath: 'docker/google-cloud', getDockerfile: true) {
                dir('guillotine') {

                    // TODO to chcke sand-baox uncomment and set the url
                    // env.GUILLOTINE_REPOSITORY_URL = 'https_sandbox_url'
                    scmUtils.checkoutRepository(env.GUILLOTINE_REPOSITORY_URL, 'master')

                    authenticateGke()
                    // Configure environment to make Guillotine works on GKE
                    withCredentials([file(credentialsId: 'jenkins-guillotine-storage-gke-sa-key', variable: 'G_STORAGE_GKE_KEY')]) {
                        sh("./configure.py env --gke-only --gke-storage-sa ${env.G_STORAGE_GKE_KEY}")
                    }

                    if (platformImageRef != ''){
                        def lastForgeopsVersion = sh(script: './configure.py --get-forgeops-last-version', returnStdout: true).trim()
                        options = "--set forgeops.versions.${lastForgeopsVersion}.platform-image-ref=${platformImageRef} ${options}"
                    }

                    options = "--set forgeops.git-url=${env.FORGEOPS_REPOSITORY_URL} ${options}"

                    // Configure Guillotine to run tests, force Guillotine to use platform images (platform version in dev)
                    sh("./configure.py runtime --forgeops-ref ${commonModule.GIT_COMMIT} ${options}")


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
