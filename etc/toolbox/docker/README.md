# Toolbox

This container has tools installed such as Helm, the kubectl command, etc. The idea
is to make it easier to get started on Kubernetes with Minikube.

The Helm charts are located in the `helm/` folder. These charts contain
Kubernetes manifests to install and configure the stack.

The images will be pulled from the ForgeRock Docker registry at `docker-public.forgerock.io`.
You need to be a staff member, and you will need to enter your backstage login id / password.

# Commands

Run `helm/bin/remove-all.sh` to clean up any old containers / pods

Run `helm/bin/openam.sh` to launch OpenAM 

Run `helm/bin/openidm.sh` to launch OpenIDM
 
# Please READ!!

It takes a *very* long time to pull images from the ForgeRock registry. The second
time you run this it should be much faster as the images will be in your Docker cache.
It may take up to 30 minutes to pull all the images.

You may see an error message "Error from server (BadRequest): container "amster" in pod "amster" is waiting to start: ContainerCreating"

This is OK - it just means the container is not present and Kubernetes must pull it. 

# Configuration
 
The configuration for the products is in /data/forgeops-init (git repo cloned from
https://github.com/ForgeRock/forgeops-init)

On Minikube the /data/ directory persists across restarts of Minikube. You can save 
work in /data. Note that if you destroy the Minikube VM, /data/ is also destroyed. 

Please send any feedback to warren.strange@forgerock.com
