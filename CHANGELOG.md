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
