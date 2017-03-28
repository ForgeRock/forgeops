
# Deployment Using Helm

See https://github.com/kubernetes/helm

If you have not already done so, install (helm)[https://github.com/kubernetes/helm].

The script bin/setup.sh will install Helm and other dependencies using homebrew.

Helm is a package manager for Kubernetes. It templates out
Kubernetes manifests by performing variable expansion using golang
templates. This enables us to have generic "charts" that can
be reused in different deployment contexts.

*** NOTE: ****  You must copy custom-template.yaml to custom.yaml, and edit the
values for your environment. The Helm charts will not install without these 
value settings. 

You must also specify the source of product configuration, which can be a Git repo or a mounted volume. 
See the section on configuration.

# Quick Start - Deploying OpenAM

* Start Minikube. `minikube start --memory=8192`
* Verify that you can use kubectl. `kubectl get pods`. At first
you will not see any output since we have not deployed anything.
You can also run `minikube dashboard`.
* Enable the Minikube ingress controller.  `minikube addons enable ingress`
* If you are using a private registry, see registry.sh. Edit the `~/etc/registry_env` and set
REGISTRY_PASSWORD, REGISTRY_ID and REGISTRY_EMAIL  environment variables with your BackStage credentials.
This is needed so that Kubernetes can authenticate to pull images from a private registry.
* Clone https://github.com/ForgeRock/forgeops-init 
* Copy custom-template.yaml to custom.yaml, and edit the variables for your environment, pointing the
forgeops-init directory you just cloned
* Run `helm init` to intialize Helm.  Wait for helm to come up:
`helm list` should not show any errors.
* Run `bin/openam.sh`. This will deploy a config store, a user store, a CTS store,
and OpenAM. This will take a few minutes on first run - be patient. You may see
error messages from the script until all the components start up.  If you want
to see what is happening, in another shell window, execute:

`kubectl get events -w`

You can also look at the pods, logs, etc. using kubectl, or the GUI dashboard.

* Put your `minikube ip` in /etc/hosts, creating an entry for openam.example.com.
* Bring up  https://openam.example.com/openam

To remove the deployment run bin/remove-all.sh. This delete the Helm
charts and the persistent volume claims backing OpenDJ.

You can scale up the replicas for OpenAM. In the dashboard, edit the Deployment for OpenAM, and set the replicas from 1 to 2 (make sure you have enough memory)

# Charts

This directory contains Helm charts for:

* opendj  - A chart to deploy one or more OpenDJ instances
* amster  - A chart to install and configure OpenAM 
* openam-runtime - A chart for the OpenAM runtime. Assumes OpenAM is
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
assume your ```custom.yaml`` file sets the DJ imageTag to "test-4.1".
You can deploy the OpenDJ chart using:

```helm install --name opendj -f custom.yaml opendj```

Further documentation can be found in each chart's README.md

# Stack Configuration Files

The OpenIDM, OpenIG, and OpenAM charts include a mechanism to import configuration from a git repository,
or to import and export configuration to a hostPath volume. 

The hostPath volume can be used in conjunction with Minikube to map a folder in your home directory 
(example: /Users/yourUsername/src/forgeops-init) to pod volumes in your Kubernetes cluster.  This enables you 
to do local development and save your configuration files to your local folder. If you place this 
folder under git, you can also track configuration changes, and push them to a remote repository.

You can supply configuration in an alternate volume by configuring the "stackConfiguration" section
in the custom.yaml file. For example:

```yaml
stackConfigSource:
  hostPath:
    path: /Users/yourUsername/tmp/fr/config
```
    
This can be any valid Kubernetes volume type. For example, if you have a PV that holds your configuration
you can mount that instead of a hostPath. (Note: hostPath *only* works on a one node cluster!)

OpenIDM in "development" mode automatically writes out changes to configuration files as they are made in the GUI 
console. OpenAM does not do this, but the OpenAM runtime chart (openam-runtime) includes an amster pod that
can map to your hostPath volume. Currently this pod just sleeps forever, but you can use `kubectl exec` to 
shell into the container, and then run the export.sh script. This script will run Amster to export the 
current configuration to the hostPath volume that is mapped to your local folder.  In the future, the export.sh
script may be configured to run periodically in the container. This would give you a pseudo export-on-change mechanism.

Please see the custom.yaml for the format of the volume mapping. 

You can edit these files, or better yet create your own custom.yaml to override those values.

# Design Notes

The default OpenDJ deployment uses persistent volume claims (PVC) and
StatefulSets to provide stateful deployment of the data tier. If you
wish to start from scratch you should delete the PVC volumes.
The remove-openam.sh script will do this for you. Note that
PVCs and StatefulSets are features introduced in Kubernetes 1.5. 

If OpenDJ is deployed with more than one server, subsequent replicas
are configured to replicate to the first instance. You need to ensure
all replicas are up and stable before proceeding to deploy OpenAM.
If you don't, you may get into a situation where OpenAM deploys,
but a new replica comes online and "replicates" on top of the install -
wiping it out.  We need to fix this in the OpenDJ chart so that
replication is initiated from the master - but this is still a work
in progress.

The shell scripts assign an explicit name to the Helm release
using the --name argument on the helm install command. If you don't do this,
Helm generates a unique release name. For scripting purposes a
fixed release name allows us to clean up the release by name.

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

You can `docker build` the images directly into the Docker instance running
inside Minikube.  Run `eval $(minikube docker-env)` to set your Docker context.

For the images' source code, see https://stash.forgerock.org/projects/DOCKER/repos/docker/browse

# Tips

To connect an LDAP browser to OpenDJ running in the cluster, use
port forwarding:

kubectl port-forward opendj-configstore-0 1389:389

# Conventions

A common Helm convention is to let Helm generate a random name for a release, and to
assign pod names based on that random name. This is useful when you want to deploy
many copies of the same chart in slightly different configurations.

This project takes a different approach of using static release names. This 
enables the charts to be more loosely coupled, but still function together. For example,
the openam chart can discover the OpenDJ configuration store because the pod name is well known. 

If you want to deploy different configurations (example: OpenAM for development, and OpenAM for QA), use Kubernetes 
namespaces.  You can modify the bin/* scripts to pass a --namespace argument to the helm command.
