# 2017-07-07

* Containers now run as the forgerock user, not root (CLOUD-90).
* New base containers java/ and tomcat/ contain common dependencies. These are based on Alpine / OpenJDK.
* Helm composite charts- requirements.yaml now reference child charts using `repository: file:../` instead of 
the forgerock/ chart repo. This makes it easier to package the charts with the `helm dep` command.
* DJ now defaults to port 1389, not 389. This is so the container can be run by the non-root forgerock user.
* Git sync functionality has been moved out of amster and into the git container. We now use sidecar git
containers for all git functionality.
