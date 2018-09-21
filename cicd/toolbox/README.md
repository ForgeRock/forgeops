# Toolbox for running in Kubernetes

This dockerfile is intended to run inside the Kubernetes cluster. It can be used to launch and orchestrate the
smoke tests, or to perform other administration functions.

It includes binaries for: helm, kubectl, kubens and kubectx.

This must be run using a service account that has cluster administration credentials.

Build this using:

docker build -t gcr.io/engineering-devops/toolbox:latest toolbox

todo: Incorporate the build of this into our CI process
