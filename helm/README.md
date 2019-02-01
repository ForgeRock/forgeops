# Helm Charts

## Setup 

1) If you have not already done so, install [helm](https://github.com/kubernetes/helm) and other dependencies. 

2) Build your Docker images, or set up access to a registry where those images can be pulled.
The default docker repository and tag names are set in each helm chart in values.yaml. You can
override these in your custom.yaml file.  

*TIP* If you are using minikube, you can docker build images directly to your docker cache, and set the chart policy to
`image.pullPolicy: IfNotPresent`


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

The default format used for the FQDN is:
{namespace}.{subdomain}.{domain}/{am|idm|ig|openidm}

subdomain defaults to "iam"

 For example:

 `default.iam.example.com`

Note that the details of the ingress will depend on the implementation. You may need to modify the ingress definitions. 
 
# TLS

All charts default to using TLS (https) for the inbound ingress.  

If you use nginx on minikube, the ingress will default to using the nginx self signed certificate. If you want to use nginx and a "real" SSL certificate you must modify the ingress.yaml in each chart, and provide a TLS secret.

For istio,  we assume  a wildcard certificate is obtained for the istio ingress for the entire cluster. 
This certificate handles SSL for all namespaces: *.$subdomain.$domain. 

Note: The frconfig chart no longer defaults to enabling cert-manager - as it is not required by default.

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

