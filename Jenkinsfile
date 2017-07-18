#!/usr/bin/env groovy

//===============================
// Postcommit pipeline for OpenIG
//===============================

// Import the pipeline libraries (for libs on development branches, use e.g. @Library('forgerock-pipeline-libs@<branch name>'))
@Library('forgerock-pipeline-libs')
import com.forgerock.pipeline.Build

// Job properties (log rotation & parameters)
properties([buildDiscarder(logRotator(daysToKeepStr: '', numToKeepStr: '10'))])

def postcommitBuild = new Build(steps, env, currentBuild)

def buildRepo = "ssh://git@stash.forgerock.org:7999/cloud/forgeops.git"
def buildBranch = 'master'


timestamps {
  node('build&&linux') {
    try {
      // The following environment variables must be set. Alternatively, the values can be passed to the postcommitBuild.mvn() command
      withEnv(["JAVA_HOME=${ tool 'JDK8' }",
               "MAVEN_OPTS=-XX:MaxPermSize=256m -Xmx1024m",
               "PATH+MAVEN=${tool 'Maven 3.2.5'}/bin"]) {
        stage ('Clone the repo/branch') {
          stageErrorMessage = 'The Git clone command failed, please check the console output'

          // Store the commit SHA of the main checkout, to use in notifications
          commitShaForNotifications = postcommitBuild.gitClone(buildRepo, buildBranch)
          postcommitBuild.setBuildNameAndDescription(buildBranch)
        }

        stage ('Docker release build') {
          stageErrorMessage = 'The Maven build failed, please check the console output'
          sh "cd docker && mvn -U clean package docker:build docker:push"
        }
        // Build after the release as we need the base java / tomcat containers.
        stage ('Docker snapshot build') {
          stageErrorMessage = 'The Maven snapshot build failed, please check the console output'
          sh "cd docker && mvn -U -Psnapshot-releases package docker:build docker:push"
        }
      }
    }
    catch(exception) {
       currentBuild.result = 'FAILURE'
      throw exception
    }
  }
}