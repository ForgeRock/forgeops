# ForgeRock DevOps and Cloud Deployment 

Docker and Kubernetes DevOps artifacts for the ForgeRock platform. 

## Disclaimer 

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


## Branches 

The master branch targets
features that are still in development and may not be stable. Please checkout the 
 branch that matches the targeted release.


For example, if you have the source checked out from git:

```bash
git checkout release/6.0.0
```

## Docker images 

Docker images are maintained in the docker/ folder. 

ForgeRock customers and partners who have access to the ForgeRock private-releases Artifactory repository
can use the dl.sh to download product binaires and can  build docker images using the build.sh script. You
must have a API Key in order to download binaries from Artifactory. 

## Documentation 

The [Draft ForgeRock DevOps Guide](https://ea.forgerock.com/docs/platform/devops-guide/index.html)
tracks the master branch.

The documentation for the current release can be found on 
[backstage](https://backstage.forgerock.com/docs/platform).

# Quick Start

* Knowledge of Kubernetes and Helm is assumed. Please read 
the [helm documentation](https://github.com/kubernetes/helm/blob/master/docs/index.md) before proceeding.
* This assumes minikube is running (8G of RAM), and helm and kubectl are installed. 
* See bin/setup.sh for a sample setup script.

```sh

# build all the docker images
cd docker
eval $(minikube docker-env)
./dl.sh
./build.sh
cd ..
# Make sure you have the ingress controller add on
minikube addon enable ingress

helm init

# Now copy helm/custom.yaml, and edit for your environment. 

cd helm/

# If you want to use the demonstration Helm chart repo, you can use this:
helm repo add forgerock https://storage.googleapis.com/forgerock-charts/
helm repo update
# deploy the platform example:
helm install -f my-custom.yaml forgerock/cmp-platform

# If you running helm charts from this source code:
./update-deps.sh   
helm install -f my-custom.yaml cmp-platform

#Get your minikube ip
minikube ip

# You can put DNS entries in an entry in /etc/hosts. For example:
# 192.168.99.100 openam.default.example.com openidm.default.example.com openig.default.example.com

open http://openam.default.example.com

# Alternatively, if you use something like xip.io, you access AM using the minikube IP:

open http://openam.default.192.168.99.100.xip.io/openam


```

To change the deployment parameters, FQDN, etc. please see the comments in helm/custom.yaml.


## Contents 

* docker/ -  contains the Dockerfiles for the various containers. 
* helm/ - contains Kubernetes helm charts to deploy those containers. See the helm/README.md
* etc/ - contains various scripts and utilities
* bin/  - Contains utility shell scripts


## Setting a namespace

If you do not want to use the 'default' namespace, set your namespace using:

kubectl config set-context $(kubectl config current-context) --namespace=<insert-namespace-name-here>
