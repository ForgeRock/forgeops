# ForgeRock DevOps and Cloud Deployment 

This repository is the master (bleeding edge) for the Docker and Kubernetes DevOps artifacts. The master targets
features that are still in development and may not be stable.

The DevOps artifacts for the 5.5.0 ForgeRock Identity Platform are on the `release/5.5.0` branch of this repository.

If you have the source checked out from git:

```bash
git checkout release/5.5.0 
```

NOTE: ForgeRock customers and partners who have access to the ForgeRock private-releases maven repository
can use the maven pom.xml to build docker images for *released* versions of the products. You
must have a settings.xml file with credentials for repository access. See the [backstage
article](https://backstage.forgerock.com/knowledge/kb/article/a74096897)


# Documentation 

The [Draft ForgeRock DevOps Guide](https://ea.forgerock.com/docs/platform/doc/backstage/devops-guide/index.html)
tracks the master branch.

The documentation for the the 5.5.0 release can be found on 
[backstage](https://backstage.forgerock.com/docs/platform/5.5/devops-guide)
as well as the previous [5.0.0 release documentation](https://backstage.forgerock.com/docs/platform/5/devops-guide).


# Quick Start
 
* Knowledge of Kubernetes and Helm is assumed. Please read 
the [helm documentation](https://github.com/kubernetes/helm/blob/master/docs/index.md) before proceeding.
* This assumes minikube is running (8G of RAM), and helm and kubectl are installed. 
* See bin/setup.sh for a sample setup script

```sh

# build all the docker images
cd docker
eval $(minikube docker-env)
mvn
cd ..
# Make sure you have the ingress controller add on
minikube addon enable ingress

helm init

# Now copy helm/custom.yaml, and edit for your environment. 

cd helm/

# If you want to use the demonstration Helm chart repo, you can use this:
helm repo add forgerock https://storage.googleapis.com/forgerock-charts/
helm repo update
# deploy the AM development example. Deploys AM, amster, and DJ config store.
# Using forgerock/ as a prefix deploys from the chart repository. For local development use the folder ./cmp-am-dev
helm install -f my-custom.yaml forgerock/cmp-am-dev 

# If you running helm charts from this source code:
./update-deps.sh   
helm install -f my-custom.yaml cmp-am-dev



# Or, deploy idm 
helm install -f my-custom.yaml ./cmp-idm-dj-postgres

#Get your minikube ip
minikube ip

# You can put DNS entries in an entry in /etc/hosts. For example:
# 192.168.99.100 openam.default.example.com openidm.default.example.com openig.default.example.com

open http://openam.default.example.com

# Alternartively, if you use something like xip.io, you access AM using the minikube IP:

open http://openam.default.192.168.99.100.xip.io/openam


```

To change the deployment parameters, FQDN, etc. please see the comments in helm/custom.yaml.


# Contents 

* docker/ -  contains the Dockerfiles for the various containers. 
* helm/ - contains Kubernetes helm charts to deploy those containers. See the helm/README.md
* etc/ - contains various scripts and utilities
* bin/  - This is a symnbolic link to docker/toolbox/bin. It contains utility shell scripts to deploy the helm charts

# Significant Changes

* The ingress now uses the namespace in the FQDN. For example, openam.default.example.com, where default
is the namespace. This allows you to run multiple instances on the same cluster
* Most charts now use generated Helm release names (i.e. random). This is necessary because 
release names needs to be unique across the cluster.
* Composite charts have been introduced. Charts starting with helm/cmp* are composite charts constructed from
other child charts.

# Setting a namespace

If you do not want to use the 'default' namespace, set your namespace using:

kubectl config set-context $(kubectl config current-context) --namespace=<insert-namespace-name-here>


# Known Issues

* minkube PVCs can not be accessed by non root containers. This is related to the minikube hostpath PVC provisioner.
This means that you can not use PVCs in minikube as DJ now runs as the forgerock user. The default DJ persistence
strategy is now set to false by default, meaning the DJ data will vanish once the pod is gone. 
Set this to true on GKE or other Cloud environments by setting `djPersistence: true` in the value overrides.
See https://github.com/kubernetes/kubernetes/issues/2630.
