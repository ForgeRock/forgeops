# Platform Sample

This is a sample project demonstrates one way to use four components of the ForgeRock Identity Platform (AM, DJ, IDM and IG). This sample demonstrates these capabilities:

External DJ cluster as a shared user store for AM and IDM
Facebook authentication with AM
Delegation of all self-service features to IDM (including automatic redirection to IDM during social authentication)
Unification of end-user interfaces - using CORS to facilitate the seamless interaction of the various back-end services

Docker and Kubernetes are used to automate the deployment of this sample. It is designed to run primarily in Minikube, and it is intentionally oversimplified in terms of its Kubernetes configuration. This sample may be useful to show the minimum necessary Kubernetes configuration, but it should not be considered a template for a production deployment. Refer to the other areas of forgeops for production-ready templates.

## Only needed once per machine:

**You need minikube 0.23+ and kubectl 1.8+ for this to work**

    minikube start --insecure-registry 10.0.0.0/24 --memory 4096
    echo "$(minikube ip) idm-service.sample.svc.cluster.local am-service.sample.svc.cluster.local" | sudo tee -a /etc/hosts

You may be prompted to enter your password after running the above commands. Afterward, run these:

    minikube addons enable ingress
    eval $(minikube docker-env)
    kubectl config set-context sample-context --namespace=sample --cluster=minikube --user=minikube
    kubectl config use-context sample-context


## Facebook usage

If you want to enable Facebook usage, you will need to register an application within Facebook. You will need to make sure your Facebook App has these redirect urls registered:

    http://idm-service.sample.svc.cluster.local/oauthReturn/
    http://am-service.sample.svc.cluster.local:80/openam/oauth2c/OAuthProxy.jsp

Save the App Id and Secret as environment variables, like so:

    export IDP_FACEBOOK_CLIENTID=<Your Facebook App Id>
    export IDP_FACEBOOK_CLIENTSECRET=<Your Facebook App Secret>

Otherwise, export dummy values:

    export IDP_FACEBOOK_CLIENTID=FakeID
    export IDP_FACEBOOK_CLIENTSECRET=FakeSecret

If you use dummy values, Facebook will still appear in your AM and IDM environments as an option, but it won't be functional.

## Starting the sample

In order to copy and paste the below commands, you will need make sure your working folder is correct. You should be in the same folder as this README file (forgeops/sample-platform).

This command needs to be executed each time you start the minikube VM, to fix a bug with its internal networking:

    minikube ssh "sudo ip link set docker0 promisc on"

Build the Docker images and add the kubernetes resources for this sample:

    docker build -t ig:fullstack igOIDC
    docker build -t dj:fullstack dj
    docker build -t am:fullstack am
    docker build -t amster:fullstack amster
    docker build -t idm:fullstack idm
    docker build -t pg:fullstack pg

    kubectl create namespace sample

    kubectl create secret generic social-credentials \
        --from-literal=IDP_FACEBOOK_CLIENTID=$IDP_FACEBOOK_CLIENTID \
        --from-literal=IDP_FACEBOOK_CLIENTSECRET=$IDP_FACEBOOK_CLIENTSECRET

    kubectl apply -f .


Monitor the pods as they come up:

    kubectl logs -f dj-0
    kubectl logs -f am
    kubectl logs -f amster
    kubectl logs -f ig
    kubectl logs -f idm

To make the internal DJ cluster accessible locally:

    kubectl port-forward dj-0 2389:1389 &

Now the environment should be available at http://idm-service.sample.svc.cluster.local

You can use amadmin / password to login.

To make REST API calls to IDM you need to include an access_token in your request, like so:

    curl -H 'x-requested-with:curl' -H 'Authorization: Bearer e3b1.......' \
     http://idm-service.sample.svc.cluster.local/openidm/...

## For developers making changes

You can deploy changes to the underlying product running in the container like so:

    cp $OPENIDM_ZIP_TARGET/openidm*.zip ../docker/openidm/openidm.zip
    docker build -t quay.io/forgerock/openidm:latest ../docker/openidm
    docker build -t idm:fullstack idm
    kubectl delete po idm --grace-period=0 --force
    kubectl apply -f idm.yml


## Saving config changes

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

Be sure to rebuild your amster image afterwards:

    docker build -t amster:fullstack amster

To destroy the environment:

    kubectl delete namespace sample
