# Platform Sample

This is a sample project demonstrates one way to use four components of the ForgeRock Identity Platform (AM, DJ, IDM and IG). This sample demonstrates these capabilities:

External DJ cluster as a shared user store for AM and IDM
Facebook authentication with AM
Delegation of all self-service features to IDM (including automatic redirection to IDM during social authentication)
Unification of end-user interfaces - using CORS to facilitate the seamless interaction of the various back-end services

Docker, Kubernetes and Helm are used to automate the deployment of this sample. It is intentionally oversimplified in terms of its Kubernetes configuration. This sample may be useful to show the minimum necessary Kubernetes configuration, but it should not be considered a template for a production deployment. Refer to the other areas of forgeops for production-ready templates.

## Optional Facebook usage

If you want to enable Facebook for social registration and login, you will need to register an application within Facebook. You will need to make sure your Facebook App has these redirect urls registered:

    http://idm-service.sample.svc.cluster.local/oauthReturn/
    http://am-service.sample.svc.cluster.local/openam

Save the App Id and Secret as environment variables, like so:

    export IDP_FACEBOOK_CLIENTID=<Your Facebook App Id>
    export IDP_FACEBOOK_CLIENTSECRET=<Your Facebook App Secret>

If you don't want to use Facebook, the default values of "FakeID" and "FakeSecret" will be used. Facebook will still appear in your AM and IDM environments as an option, but it won't be functional.

## Quick Start

1. If you have Helm installed and you have kubectl setup to work with your Kubernetes cluster, then you can get started very quickly with these commands:
```
helm init --wait
helm repo add forgerock https://storage.googleapis.com/forgerock-charts
helm install forgerock/fr-platform -n sample-fr-platform \
  --set-string social.facebook.id=${IDP_FACEBOOK_CLIENTID} \
  --set-string social.facebook.secret=${IDP_FACEBOOK_CLIENTSECRET}
```

2. You need to add the ingress IP to your local hosts. First, remove any old entry with this command:
```
grep -v idm-service.sample.svc.cluster.local /etc/hosts \
| sudo tee /etc/hosts
```
Next add the correct entry:

    If you are using minikube, use this command:
```
echo "$(minikube ip) \
    idm-service.sample.svc.cluster.local \
    am-service.sample.svc.cluster.local" \
| sudo tee -a /etc/hosts
```
If your cluster is available directly, you can use this command instead:
```
echo "$( kubectl get ing -o \
    jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' ) \
    idm-service.sample.svc.cluster.local \
    am-service.sample.svc.cluster.local" \
| sudo tee -a /etc/hosts
```

3. Wait for all of the pods to become ready:
```
kubectl get po -n sample --watch
```

4. Afterwards, you can access the application by opening this URL:
```
http://idm-service.sample.svc.cluster.local
```

    You can use amadmin / password to login.

5. You can remove the sample like so:
```
helm delete --purge sample-fr-platform
```

## Building and Running locally

To start the project locally, you need at least a 4gb node. The best option is to use minikube, like so:

    minikube start --insecure-registry 10.0.0.0/24 --memory 4096
    minikube addons enable ingress
    eval $(minikube docker-env)
    kubectl config set-context sample-context --namespace=sample --cluster=minikube --user=minikube
    kubectl config use-context sample-context
    minikube ssh "sudo ip link set docker0 promisc on"

### Building the Docker images and helm package

In order to copy and paste the below commands, you will need make sure your working folder is correct. You should be in the same folder as this README file (forgeops/sample-platform).

Build the Docker images for this sample:

    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/ig:6.0.0 igOIDC
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/dj:6.0.0 dj
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/am:6.0.0 am
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/amster:6.0.0 amster
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/idm:6.0.0 idm
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/pg:6.0.0 pg

Install the helm package:

    helm init --wait
    helm package .
    helm install fr-platform-6.0.0.tgz -n sample-fr-platform \
      --set-string social.facebook.id=${IDP_FACEBOOK_CLIENTID} \
      --set-string social.facebook.secret=${IDP_FACEBOOK_CLIENTSECRET}

You can now follow the steps described in the "Quick Start" section, starting from (2).

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
