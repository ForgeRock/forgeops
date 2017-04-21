
# Deployment Using Helm

See https://github.com/kubernetes/helm

Helm is a package manager for Kubernetes. It templates out
Kubernetes manifests by performing variable expansion using golang
templates. This enables us to have generic "charts" that can
be reused in different deployment contexts.


# Setup 

1) If you have not already done so, install (helm)[https://github.com/kubernetes/helm] and other dependencies. The script `bin/setup.sh` will install these on a Mac using homebrew. You may have to ajdust this script for your environment.

2) Create a custom.yaml file in the helm directory. You can copy a sample from the templates/ directory. This file sets the value overrides for things like the cooke domain, git repository, etc.

3) Decide on a git configuration source for the initial product configuration. Edit the git: value in custom.yaml to 
point to this source. 

4) Build your Docker images, or set up access to a registry where those images can be pulled. The default docker repository and tag names are set in each helm chart in values.yaml. You may have to override these in your custom.yaml file.  The default assumes the docker images are in the docker cache (i.e. you have done a docker build direct to the minikube docker machine). See the README in the docker/ folder for more information.



# Configuration

The default configuration used to bootstrap the system comes from a git repository. The default repository used in the charts is:

```
git:
 repo: "https://stash.forgerock.org/scm/cloud/forgeops-init.git"
 branch: master
```

forgeops-init.git has public read-only access.  You can clone this repository but you can not write to it. 

If you wish to use your own git repository, you can fork and clone the forgeops-init repository as a starter, and then make changes as required. To modify and save a configuration:

* For AM, export the configuration using Amster.
* For IDM, simply modify the configuration; it is saved automatically if IDM has been configured to sync back changes, which is the default configuration.


The Docker images have the git command installed. To save configuration changes to your own repository, use the SSH protocol to access git. The Docker containers are configured such that your git SSH key should be held in the Kubernetes secret  `git-creds`. The shell script `bin/setup-git-creds.sh` will create this secret for you. You may have to edit this to work in your environment.

After you have set up your SSH key, you can `kubectl exec` into a running amster or openidm pod, export the configuration (if appropriate), commit the changes using `git commit`, and then push your changes using `git push`.


# Scripts

There are various sample scripts in bin/ that you can modify as needed for your environment. These scripts run helm and kubectl commands to deploy the products.  Some examples:

* open{am,idm,ig,dj}.sh - Deploys the various products
* start-all.sh - deploys all products
* remove-all.sh  - removes all deployments

# Quick Start - Deploying OpenAM

* Start Minikube. `minikube start --memory=8192`
* Verify that you can use kubectl. `kubectl get pods`. At first
you will not see any output since we have not deployed anything.
You can also run `minikube dashboard`.
* Enable the Minikube ingress controller.  `minikube addons enable ingress`
* If you are using a private registry, see registry.sh. Edit the `~/etc/registry_env` and set
REGISTRY_PASSWORD, REGISTRY_ID and REGISTRY_EMAIL  environment variables with your BackStage credentials.
This is needed so that Kubernetes can authenticate to pull images from a private registry. NOTE AT THIS TIME THAT THE FORGEROCK DOCKER REGISTRY IS ONLY AVAILABLE TO EMPLOYEES.
* Clone https://stash.forgerock.org/projects/CLOUD/repos/forgeops-init
* Copy template/custom.yaml to custom.yaml, and edit the variables for your environment.
* Run `helm init` to intialize Helm.  Wait for helm to come up:
`helm list` should not show any errors.
* Run `bin/openam.sh`. This will deploy a config store, a user store, a CTS store,
and OpenAM. This will take a few minutes on first run - be patient. You may see
error messages from the script until all the components start up.  If you want
to see what is happening, in another shell window, execute:

`kubectl get events -w`

You can also look at the pods, logs, etc. using kubectl, or the GUI dashboard.

* Run the `minikube ip` command to obtain the IP address of your deployment, and then add an entry in your /etc/hosts file with the IP address and the FQDN an entry for openam.default.example.com.
* Bring up  https://openam.default.example.com/openam

To remove the deployment run bin/remove-all.sh. This delete the Helm
charts and the persistent volume claims backing OpenDJ.

You can scale up the replicas for OpenAM. In the dashboard, edit the Deployment for OpenAM, and set the replicas from 1 to 2 (make sure you have enough memory)

# Charts

This directory contains Helm charts for:

* opendj  - A chart to deploy one or more OpenDJ instances
* amster  - A chart to install and configure OpenAM 
* openam - A chart for the OpenAM runtime. Assumes OpenAM is
installed already. This can scale up horizontally by increasing the replica count.
* openidm - OpenIDM
* postgres-opendim - Configures a Postgresql repository database for OpenIDM
* openig -  OpenIG

Please see ../README.md for instructions on accessing a private docker registry.

# Modifying the Deployment

Each Helm chart has a values.yaml file that contains default
chart values for things like the Docker image, number of replicas, and
so on.  You can either edit the charts' values.yaml files, or better yet, create
your own value overrides in the custom.yaml file that override just the values you want to
change. You can then invoke Helm with your custom values. 

For example,
assume your ```custom.yaml`` file sets the DJ image tag to "test-4.1".
You can deploy the OpenDJ chart using:

```helm install -f custom.yaml opendj```

Further documentation can be found in each chart's README.md

# Namespaces 

By default, the charts will deploy to the `default` namespace in Kubernetes. You can switch namespaces using the command `bin/set-namespace.sh  NAMESPACE`.  This will change your namespace context in kubectl to the new namespace, and will result in the products being deployed to that namespace. You can deploy multiple product instances in different namespaces and they will not interfere with each other. For example, you might have 'dev', 'qa', and 'prod' namespaces. 

To provide external ingress routes that are unique, the namespace is used when forming the ingress host name. The format is:
 {openam,openidm,openig}.{namespace}.{cookieDomain} 

 For example:

 `openam.default.example.com`


# Design Notes

OpenIDM in "development" mode automatically writes out changes to configuration files as they are made in the GUI 
console. OpenAM does not do this, but the OpenAM runtime chart (openam) includes an amster pod that
can export configuration. Currently this pod just sleeps forever, but you can use `kubectl exec` to 
shell into the container, and then run the export.sh script. This script will run Amster to export the 
current configuration to /git.  In the future, the export.sh
script may be configured to run periodically in the container. This would give you a pseudo export-on-change mechanism.

The default OpenDJ deployment uses persistent volume claims (PVC) and
StatefulSets to provide stateful deployment of the data tier. If you
wish to start from scratch you should delete the PVC volumes.
The remove-openam.sh script will do this for you. Note that
PVCs and StatefulSets are features introduced in Kubernetes 1.5. 

If you are using Minikube take note that host path PVCs get deleted
everytime Minikube is restarted.  The opendj/ chart is a StatefulSet,
and relies on auto provisioning.  If you restart Minikube, you may find you
need to re-install OpenAM.

# Docker Images

These charts uses the following ForgeRock Docker images:

* forgerock/openam  - OpenAM runtime image
* forgerock/opendj  - OpenDJ for the config / user store
* forgerock/amster -    Amster configuration client for OpenAM
* forgerock/openig  - OpenIG runtime image
* forgerock/openidm  - OpenIDM runtime image

The Dockerfiles for these images are in the docker/ folder. You can `docker build` the images directly into the Docker instance running
inside Minikube.  Run `eval $(minikube docker-env)` to set your Docker context.

# Tips

To connect an LDAP browser to OpenDJ running in the cluster, use
port forwarding:

kubectl port-forward opendj-configstore-0 1389:389


