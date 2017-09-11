# Toolbox

This container has tools installed such as Helm, the kubectl command, etc. The idea
is to make it easier to get started on Kubernetes with Minikube. This is a work in progress
and is not currently used. 

# Please READ!!

It takes a *very* long time to pull images from the ForgeRock registry. The second
time you run this it should be much faster as the images will be in your Docker cache.
It may take up to 30 minutes to pull all the images.

You may see an error message "Error from server (BadRequest): container "amster" in pod "amster" is waiting to start: ContainerCreating"

This is OK - it just means the container is not present and Kubernetes is still pulling it.

# Configuration
 
The configuration for the products is in /git/forgeops-init (git repo cloned from
https://github.com/ForgeRock/forgeops-init)

