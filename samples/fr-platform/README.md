# Platform Sample

This is a sample project demonstrates one way to use four components of the ForgeRock Identity Platform (AM, DJ, IDM and IG). This sample demonstrates these capabilities:

External DJ cluster as a shared user store for AM and IDM
Facebook authentication with AM
Delegation of all self-service features to IDM (including automatic redirection to IDM during social authentication)
Unification of end-user interfaces - using CORS to facilitate the seamless interaction of the various back-end services

Docker, Kubernetes and Helm are used to automate the deployment of this sample. It is intentionally oversimplified in terms of its Kubernetes configuration. This sample may be useful to show the minimum necessary Kubernetes configuration, but it should not be considered a template for a production deployment. Refer to the other areas of forgeops for production-ready templates.

## Optional Facebook usage

If you want to enable Facebook for social registration and login, you will need to register an application within Facebook. You will need to make sure your Facebook App has these redirect urls registered:

    http://client-service.sample.svc.cluster.local/oauthReturn/
    http://am-service.sample.svc.cluster.local/openam

Save the App Id and Secret as environment variables, like so:

    export IDP_FACEBOOK_CLIENTID=<Your Facebook App Id>
    export IDP_FACEBOOK_CLIENTSECRET=<Your Facebook App Secret>

If you don't want to use Facebook, the default values of "FakeID" and "FakeSecret" will be used. Facebook will still appear in your AM and IDM environments as an option, but it won't be functional.

## Quick Start

0. *(Optional, for local use)* If you do not have kubectl and helm already configured, you can initialize them in your local environment like so:
```
minikube start --insecure-registry 10.0.0.0/24 --memory 4096
minikube addons enable ingress
eval $(minikube docker-env)
kubectl config set-context sample-context --namespace=sample --cluster=minikube --user=minikube
kubectl config use-context sample-context
minikube ssh "sudo ip link set docker0 promisc on"
helm init --wait
```

1. With Helm installed and kubectl setup to work with your Kubernetes cluster (either local or remote), then you can get started very quickly with these commands:
```
helm repo add forgerock https://storage.googleapis.com/forgerock-charts
helm install forgerock/fr-platform -n sample-fr-platform \
  --set-string social.facebook.id=${IDP_FACEBOOK_CLIENTID} \
  --set-string social.facebook.secret=${IDP_FACEBOOK_CLIENTSECRET}
```


2. You need to add the ingress IP to your local hosts. First, remove any old entry with this command:
```
grep -v client-service.sample.svc.cluster.local /etc/hosts \
| sudo tee /etc/hosts
```
Next add the correct entry:

    If you are using minikube, use this command:
```
echo "$(minikube ip) \
    client-service.sample.svc.cluster.local \
    am-service.sample.svc.cluster.local" \
| sudo tee -a /etc/hosts
minikube ssh "sudo ip link set docker0 promisc on"
```
If your cluster is available directly, you can use this command instead:
```
echo "$( kubectl get ing -o \
    jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' ) \
    client-service.sample.svc.cluster.local \
    am-service.sample.svc.cluster.local" \
| sudo tee -a /etc/hosts
```

3. Wait for all of the pods to become ready:
```
kubectl get po -n sample --watch
```

4. Afterwards, you can access the application by opening this URL:
```
http://client-service.sample.svc.cluster.local
```

    You can use amadmin / password to login.

5. You can remove the sample like so:
```
helm delete --purge sample-fr-platform
```

## Local Kubernetes and Helm setup

To start the project locally, you need at least a 4gb minikube node. Setup your local node using the instructions provided in the *(Optional, for local use)* step above.

The best option for making changes to the sample is to use the "skaffold" tool, available here: https://github.com/GoogleContainerTools/skaffold
Once it is installed and your minikube environment is ready, you can start the whole sample with one command:

    skaffold dev

This will build the docker images and incorporate them into the helm templates, followed by managing the release of the chart. Any changes made to the configuration files for each docker image will be watched by skaffold, and will result in an automatic rebuild of the image followed by a redeployment into the cluster.

### Manually building the Docker images and helm package

When you are done making changes to the base configuration, you can create final docker images and helm packages with the below commands.

Build the Docker images for this sample:

    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/rs:latest rs
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/client:latest client
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/dj:latest dj
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/am:latest am
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/amster:latest amster
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/idm:latest idm
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/pg:latest pg

You can now push these to a docker registry, if that is needed.

Create the helm package:

    helm package .

You now have a file names something like fr-platform-6.5.0-SNAPSHOT.tgz that you can publish to a helm repositories. Afterwards you can follow the steps described in the "Quick Start" section, similar to what is shown in step 1.

## Connecting to your cluster

To make the internal DJ cluster accessible locally:

    kubectl port-forward dj-0 2389:1389 &

## Saving configuration changes

To export changes made to AM:

    kubectl exec -it amster /opt/amster/amster
      connect http://am-service.sample.svc.cluster.local/openam -k /var/run/secrets/amster/id_rsa
      export-config --path /tmp/export
      :quit

    kubectl cp amster:/tmp/export amster/config


To export changes made to IDM:

    kubectl cp idm:/opt/openidm/conf idm/conf

Review changes to config using git diff. Remove all untracked files with this command:

    git clean -fdx

Be sure to rebuild your docker images afterwards.
