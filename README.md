# ForgeRock DevOps and Cloud Deployment 

Docker and Kubernetes DevOps artifacts for the ForgeRock platform. 

# Disclaimer 

These samples are provided on an “as is” basis, without warranty of any kind, to the fullest extent 
permitted by law. ForgeRock does not warrant or guarantee the individual success developers 
may have in implementing the code on their development platforms or in 
production configurations. ForgeRock does not warrant, guarantee or make any representations 
regarding the use, results of use, accuracy, timeliness or completeness of any data or 
information relating to these samples. ForgeRock disclaims all warranties, expressed or implied, and 
in particular, disclaims all warranties of merchantability, and warranties related to the code, or any 
service or software related thereto. ForgeRock shall not be liable for any direct, indirect or 
consequential damages or costs of any type arising out of any action taken by you or others related 
to the samples.


# Branches 

The master branch targets
features that are still in development and may not be stable. Please checkout the 
 branch that matches the targeted release.


For example, if you have the source checked out from git:

```bash
git checkout release/x.y.0 
```

# Docker images 

Docker images are maintained in the docker/ folder. 

ForgeRock customers and partners who have access to the ForgeRock private-releases maven repository
can use the maven pom.xml to build docker images for *released* versions of the product. You
must have a settings.xml file with credentials for repository access. See the [backstage
article](https://backstage.forgerock.com/knowledge/kb/article/a74096897)


# Documentation 

The [Draft ForgeRock DevOps Guide](https://ea.forgerock.com/docs/platform/devops-guide/index.html)
tracks the master branch.

The documentation for the current release can be found on 
[backstage](https://backstage.forgerock.com/docs/platform).

# Quick Start

There is now a sample "bootstrap" script. See bin/bootstrap.sh. The bootstrap
script uses a toolbox docker image that contains the helm and kubectl commands and can bring up the
platform. See the etc/toolbox.yaml for an example of how this works.


* Knowledge of Kubernetes and Helm is assumed. Please read 
the [helm documentation](https://github.com/kubernetes/helm/blob/master/docs/index.md) before proceeding.
* This assumes minikube is running (8G of RAM), and helm and kubectl are installed. 
* See bin/setup.sh for a sample setup script.

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

# Alternatively, if you use something like xip.io, you access AM using the minikube IP:

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
