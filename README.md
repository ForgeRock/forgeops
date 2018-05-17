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
git checkout release/x.y.0 
```


## Contents 

* docker/ -  contains the Dockerfiles for the various containers. 
* helm/ - contains Kubernetes helm charts to deploy those containers. See the helm/README.md
* etc/ - contains various scripts and utilities
* bin/  - Utility shell scripts to deploy the helm charts

## Docker images 

See the [docker/README.md](docker/README.md) for instructions on how to build your own docker images.

## Documentation 

The [Draft ForgeRock DevOps Guide](https://ea.forgerock.com/docs/platform/devops-guide/index.html)
tracks the master branch.

The documentation for the current release can be found on 
[backstage](https://backstage.forgerock.com/docs/platform).

## Sample Session

* Knowledge of Kubernetes and Helm is assumed. Please read 
the [helm documentation](https://github.com/kubernetes/helm/blob/master/docs/index.md) before proceeding.
* This assumes minikube is running (8G of RAM), and helm and kubectl are installed. 
* See bin/setup.sh for a sample setup script.

```sh

# Make sure you have the ingress controller add on
minikube addon enable ingress

helm init

cd helm/

# If you want to use the demonstration Helm chart repo, you can use this:
helm repo add forgerock https://storage.googleapis.com/forgerock-charts/
helm repo update
# deploy the AM development example. Deploys AM, amster, and DJ config store.
# Using forgerock/ as a prefix deploys from the chart repository. For local development use the folder ./cmp-am-dev
helm install -f my-custom.yaml forgerock/cmp-platform

# Or, deploy from local helm charts..
./update-deps.sh
helm install -f my-custom.yaml ./cmp-platform

#Get your minikube ip
minikube ip

# You can put DNS entries in an entry in /etc/hosts. For example:
# 192.168.99.100 openam.default.example.com openidm.default.example.com openig.default.example.com

open http://openam.default.example.com

# Alternatively, if you use something like xip.io for your domain, you access AM using the minikube IP:

open http://openam.default.192.168.99.100.xip.io/openam


```

To change the deployment parameters, FQDN, etc. please see the comments in helm/custom.yaml.


## Helm values.yaml overrides.

The individual charts all have parmeters which you can override to control the deployment. For example,
setting the domain FQDN. 

Please refer to the chart settings.


## Setting a namespace

If you do not want to use the 'default' namespace, set your namespace using:

kubectl config set-context $(kubectl config current-context) --namespace=<insert-namespace-name-here>

The `kubectx` and `kubens` utilities are recommended.
