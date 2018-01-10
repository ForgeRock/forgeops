# Setup 

1) If you have not already done so, install (helm)[https://github.com/kubernetes/helm] and other dependencies. The script `bin/setup.sh` will install these on a Mac using homebrew. You may have to ajdust this script for your environment.

2) See the comments in custom.yaml. You can copy this file and customize.

3) Build your Docker images, or set up access to a registry where those images can be pulled. 
The default docker repository and tag names are set in each helm chart in values.yaml. You can 
override these in your custom.yaml file.  The default assumes the docker images are in the docker cache 
(i.e. you have done a docker build direct to the Minikube docker machine). See the
 README in the docker/ folder for more information.


# Configuration

The configuration used to bootstrap the system comes from a git repository. 
The default repository used in the charts is:

```
global:
    git:
     repo: "https://stash.forgerock.org/scm/cloud/forgeops-init.git"
     branch: release/5.5.0
```

forgeops-init.git has public read-only access.  You can clone this repository but you can not write to it. 

If you wish to use your own Git repository based on the forgeops-init repository, 
you can fork and clone the forgeops-init repository.

# Composite Charts


Composite charts have names that begin with cmp-. These charts assemble foundational charts such opendj, git, 
 openam, etc. Refer to the values.yaml in each composite chart.  If you are building the
 charts yourself, remember to perform a `helm dep up cmp-chart` to update any dependencies that might have changed.
 
# Using a private registry

* If you are using a private registry, see registry.sh. Edit the `~/etc/registry_env` and set
REGISTRY_PASSWORD, REGISTRY_ID and REGISTRY_EMAIL  environment variables with your BackStage credentials.
This is needed so that Kubernetes can authenticate to pull images from a private registry. 
NOTE AT THIS TIME THAT THE FORGEROCK DOCKER REGISTRY IS ONLY AVAILABLE TO EMPLOYEES.

If you are using your own private registry you must modify registry.sh with the relevant credentials.

# Charts

This directory contains Helm charts for:

* opendj  - A chart to deploy one or more OpenDJ instances
* amster  - A chart to install and configure OpenAM 
* openam - A chart for the OpenAM runtime. Assumes OpenAM is
installed already. This can scale up horizontally by increasing the replica count.
* openidm - OpenIDM
* postgres-opendim - Configures a Postgresql repository database for OpenIDM
* openig -  OpenIG
* cmp-*  - charts that begin with cmp are "composite" charts that include other charts



# Modifying the Deployment

Each Helm chart has a values.yaml file that contains default
chart values for things like the Docker image, number of replicas, etc.
 You can either edit the charts' values.yaml files, or better yet, create
your own value overrides in a custom.yaml file that override just the values you want to
change. You can then invoke Helm with your custom values. 

For example,
assume your ```custom.yaml`` file sets the DJ image tag to "test-4.1".
You can deploy the OpenDJ chart using:

```helm install -f custom.yaml opendj```

Further documentation can be found in each chart's README.md

# Namespaces 

By default, the charts will deploy to the `default` namespace in Kubernetes. 

You can switch namespaces using the command `bin/set-namespace.sh  NAMESPACE`.  This will 
change your namespace context in kubectl to the new namespace, and will result in the products being 
deployed to that namespace. You can deploy multiple product instances in different namespaces and they will not 
interfere with each other. For example, you might have 'dev', 'qa', and 'prod' namespaces. 

To provide external ingress routes that are unique, the namespace is used when forming the 
ingress host name. The format is:
 {openam,openidm,openig}.{namespace}.{domain} 

 For example:

 `openam.default.example.com`


# Notes

OpenIDM in "development" mode automatically writes out changes to configuration files as they are made in the GUI 
console. OpenAM does not do this, but the amster chart includes a script that loops and exports
the configuration every 90 seconds. 

You can use `kubectl exec` to 
shell into the container and run the export.sh script. This script will run Amster to export the 
current configuration to /git.  


The default OpenDJ deployment uses persistent volume claims (PVC) and
StatefulSets to provide stateful deployment of the data tier. If you
wish to start from scratch you should delete the PVC volumes.
PVCs and StatefulSets are features introduced in Kubernetes 1.5. 

If you are using Minikube take note that host path PVCs get deleted
every time Minikube is restarted.  The opendj/ chart is a StatefulSet,
and relies on auto provisioning.  If you restart Minikube, you may find you
need to re-install OpenAM.


# Tips

To connect an LDAP browser to OpenDJ running in the cluster, use
port forwarding:

kubectl port-forward opendj-configstore-0 1389:1389


To see what is going on in Kubernetes try:

`kubectl get events -w`

You can also look at the pods, logs, etc. using kubectl, or the GUI dashboard.

* Run the `minikube ip` command to obtain the IP address of your deployment, and then add an entry in your /etc/hosts file with the IP address and the FQDN an entry for openam.default.example.com.

