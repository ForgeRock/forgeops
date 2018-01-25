# 2017-07-07

* Containers now run as the forgerock user, not root (CLOUD-90).
* New base containers java/ and tomcat/ contain common dependencies. These are based on Alpine / OpenJDK.
* Helm composite charts- requirements.yaml now reference child charts using `repository: file:../` instead of 
the forgerock/ chart repo. This makes it easier to package the charts with the `helm dep` command.
* DJ now defaults to port 1389, not 389. This is so the container can be run by the non-root forgerock user.
* Git sync functionality has been moved out of amster and into the git container. We now use sidecar git
containers for all git functionality.

# 2017-07-10

* Added openam chart variable to conditionally create a bootstrap file or not. Used for embedded DJ.
* Renamed am-embedded-dj to cmp-am-embedded to reflect that it is a composite chart.
* Added git.pushInterval variable to set the interval in seconds to perform git push. 
If set to 0, push is disabled. See custom.yaml.

# 2017-07-12

* pom.xml updated to create release (5.5.0) and snapshot (5.5.0-SNAPSHOT) tags using a maven profile.

# 2017-07-13

* Added opendj-git chart to pull DJ configuration from Git.
* Changed git chart to use a release name in the configmap and secret. This avoids name 
conflicts if multiple composite charts include git.
* Removed bin/openam.sh, as this strategy will no longer work with the above change. The git 
release name will not be known to the other charts.
* Added a Jenkinsfile for pipeline builds.
* Removed CPU resource limits for am,dj and idm charts. For minikube and small scale testing this makes
it easier to fit the pods into a resource constrained cluster. For production, the resource 
limits should be set.

# 2017-07-21

* Fixed openig chart to include git dependency.
* Added rebuild.sh to opendj docker container to rebuild indexes.
* Simplified AM audit logging

# 2017-08-11

* Removed git helm chart. 
* Refactored other composite charts to directly set git configmaps and secrets. The git 
sub-chart was causing more problems than it solved.

# 2017-08-22 

* Deprecated the git auto-sync behaviour. To sync git, exec into the amster or idm containers and directly
execute git commands. 

# 2017-08-24

* Add sed filter to custom.yaml to run search/replace after git clone.


# 2017-08-25

* Add support for GCP cloud builder. Builds and pushed images to gcr.io. Also build helm charts and pushes to 
a cloud bucket.

# 2017-09-05

* Add pre-start hook to openam dockerfile for customizing the war before AM starts.
* Migrate bootstrap setup from the amster container to openam. Now that AM has a custom entrypoint,
it makes more sense to move this logic to AM.

# 2017-09-08

* Add support for customizing the AM war file before AM starts

# 2017-09-27

* Version updates for platform binaries. Documentation updates to prep for release.
* Add helm/update-deps.sh script to update Helm dependencies for local install.

# 2017-10-27 

* Update for 5.5.1 
* Update git container to enable checking out a specific commit (not just a branch)
* Update deployment.spec for amster, ig, and openidm so that changes to the git configuration
will trigger a rolling update. 

# 2017-11-06 
* Remove use of the projectDirectory. Git configuration is now checked out to a fixed directory /git/config
* update default build tag to 6.0.0-SNAPSHOT
* Add idm/am integration variable openidm.idpconfig.clientsecret.

# 2017-11-10
* All charts now use a standard git-ssh-key secret for accessing the configuration repository. This 
secret must be created before installing any helm charts. See the README.md
* Created a bootstrap.sh script to create the secret and perform a helm install.

# 2017-11-22 
* Simplifed AM image. It no longer contains bootstrap logic. This will make it easier to reuse the AM image
in different contexts.
* Created forgerock/util Docker image. Used in init containers to create bootstrap files, copy secrets, etc.
* Removed tomcat image as IG was the only product using it.

# 2017-12-01 
* Add RBAC support for AM chart
* Remove AM embedded DJ chart. This is not the recommended way to deploy AM. 

# 2017-12-20
* Removed git and ssh from all base images except for the git image
* Add git sidecar image to amster and openidm for sync
* Some minor updates to harden the docker images
* Further work on the toolbox container


# 2018-01-24
* Moved all utility and base images to https://github.com/ForgeRock/docker-public 