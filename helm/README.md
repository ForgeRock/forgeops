# Helm Charts

## Setup 

1) If you have not already done so, install [helm](https://github.com/kubernetes/helm) and other dependencies. The script `bin/setup.sh` will install these on a Mac using homebrew. You may have to ajdust this script for your environment.

2) Build your Docker images, or set up access to a registry where those images can be pulled.
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
     repo: "https://github.com/ForgeRock/forgeops-init.git"
     branch: master
```

forgeops-init.git has public read-only access.  You can clone this repository but you can not write to it.

If you wish to use your own Git repository based on the forgeops-init repository,
you can fork and clone the forgeops-init repository. See [frconfig/README.md](frconfig/README.md).

# Composite Charts

The provided cmp-platform chart bundles other foundational charts such opendj, frconfig,
 openam, etc. Performing a `helm install cmp-platform`  will deploy all the components.
 Remember to perform a `helm dep up cmp-platform` to update any dependencies that might have changed.

This chart is a simple example for use only when working through the *DevOps 
 Quick Start Guide* only.  

For all other deployments, install individual Helm charts as described in the 
 *DevOps Developer's Guide*. 
 
# Using a private registry

* If you are using a private registry, see registry.sh. Edit the `~/etc/registry_env` and set
REGISTRY_PASSWORD, REGISTRY_ID and REGISTRY_EMAIL  environment variables with your BackStage credentials.
This is needed so that Kubernetes can authenticate to pull images from a private registry. 

If you are using your own private registry you must modify registry.sh with the relevant credentials.

# Charts

This directory contains Helm charts for:

* ds  - A chart to deploy one or more DS instances
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
assume your ```custom.yaml`` file sets the DS image tag to "test-4.1".
You can deploy the DS chart using:

```helm install -f custom.yaml ds```

Further documentation can be found in each chart's README.md

# Namespaces 

By default charts  deploy to the `default` namespace in Kubernetes. 

You can deploy multiple product instances in different namespaces and they will not 
interfere with each other. For example, you might have 'dev', 'qa', and 'prod' namespaces. 

To provide external ingress routes that are unique, the namespace can be used when forming the 
ingress host name. The format is:
 {openam,openidm,openig}.{namespace}.{domain} 

 For example:

 `login.default.example.com`

Note that the details of the ingress will depend on the implementation. You may need to modify the ingress definitions. 
 
# TLS

All charts default to using TLS (https) for the inbound ingress.  

Within a namespace, it is assumed that a single wildcard certificate secret is present `wildcard.$namespace.$domain`. This
secret is referenced by each ingress controller in the `tls` spec.

You can create the wildcard secret manually, but in these examples we assume
that [cert-manager](https://github.com/jetstack/cert-manager) is installed and is provisioning certificates for you.


The frconfig chart defaults to creating a cert-manager "CA" issuer. This is a simple issuer that issues certificates signed by a CA certificate installed as part of the frconfig chart. We have included a default CA certificate in frconfig/secrets. You can replace this with your own using the sample script `frconfig/secrets/cm.sh`, or replace it with an intermediate signing certificate issued by your organization.

If you are on minikube, cert-manager can be installed using:

`helm upgrade -i cert-manager --namespace kube-system stable/cert-manager`

If you deploy the frconfig chart as-is: `helm install frconfig`  things should "just work". You will get a
self signed certificate presented to the browser. You must accept the browser warnings, or import the CA cert found in frconfig/secrets into your browser's trusted certificate list.

Alternatively, you can configure frconfig to create a cert-manager issuer for Let's Encrypt. Refer to the cert-manager docs for further details.

If you do not see a secret `wildcard.$namespace.$domain`, it means that something has gone wrong with cert manager. Look in the cert-manager logs to find the cause. If you are using the Let's Encrypt issuer, keep in mind that it can take up to 10 minutes to provision a certificate.


For further information on the above options, see the [DevOps developers guide](https://ea.forgerock.com/docs/platform/devops-guide/index.html#devops-implementation-env-https-access-secret).

# Notes

OpenIDM in "development" mode automatically writes out changes to configuration files as they are made in the GUI 
console. OpenAM does not do this, but the amster chart includes a script that loops and exports
the configuration every 90 seconds. 

You can use `kubectl exec` to 
shell into the container and run the export.sh script. This script will run Amster to export the 
current configuration to /git.  


The default DS deployment uses persistent volume claims (PVC) and
StatefulSets to provide stateful deployment of the data tier. If you
wish to start from scratch you should delete the PVC volumes.
PVCs and StatefulSets are features introduced in Kubernetes 1.5. 

If you are using Minikube take note that host path PVCs get deleted
every time Minikube is restarted.  The ds/ chart is a StatefulSet,
and relies on auto provisioning.  If you restart Minikube, you may find you
need to re-install OpenAM.

# Dependencies

The script `helm/update-deps.sh` will update all of the dependencies. You must run this anytime you change  any of the foundational charts (openam, openidm, etc.)

# Tips

To connect an LDAP browser to DS running in the cluster, use
port forwarding:

kubectl port-forward opendj-configstore-0 1389:1389


To see what is going on in Kubernetes try:

`kubectl get events -w`

You can also look at the pods, logs, etc. using kubectl, or the GUI dashboard.

* Run the `minikube ip` command to obtain the IP address of your deployment, and then add an entry in your /etc/hosts file with the IP address and the FQDN an entry for openam.default.example.com.

