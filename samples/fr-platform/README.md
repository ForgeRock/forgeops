# Platform OAuth2 Sample

This is a sample project demonstrates one way to use four components of the ForgeRock Identity Platform (AM, DS, IDM and IG). This sample demonstrates these capabilities:

IG protecting IDM as an OAuth2 Resource Server for end-user interaction

External DS cluster as a shared user store for AM and IDM

**There is no OAuth2 client shipped with this sample**. Refer to the [Example OAuth 2 Clients Project](https://github.com/ForgeRock/exampleOAuth2Clients) to find a sample client that will be the most useful for your needs.

Docker, Kubernetes and Helm are used to automate the deployment of this sample. The main "openam" and "ds" helm charts are used to start those services. The configuration for all of the products is stored within this sample folder:

 - "amster" contains the AM configuration
 - "rs" contains the IG configuration
 - "idm" contains the IDM configuration
 - "pg" contains the PostgreSQL configuration (used for IDM workflow)

 The helm charts included under the "templates" folder are intentionally oversimplified in terms of their Kubernetes configuration. They should not be considered a pattern for a production deployment. Refer to the other areas of forgeops for production-ready templates.

## Running the Sample

*Note: skip the "optional" steps below if you are working with a hosted Kubernetes provider and have already setup your kubectl and helm environment.*

1. *(Optional - initial minikube vm setup)* If you want to run the sample locally in minikube, you first need to prepare your minikube VM. This is only needed the first time you setup your minikube VM; if you restart your host or your VM, you do not need to repeat this setup.

    This creates the minikube VM, enables the ingress addon, adds a new namespace to your kubectl config, and initializes the helm tiller:

    ```
    minikube start --insecure-registry 10.0.0.0/24 --memory 4096 && \
    minikube addons enable ingress && \
    kubectl config set-context sample-context --namespace=sample --cluster=minikube --user=minikube && \
    sleep 2 && \
    helm init --wait
    ```

2. *(Optional - prep minikube for use)* If you are using minikube, you will need to run these commands every time the VM starts (after first setup as well as after every reboot).

    These commands fix a bug in minikube related to loopback networking, prepare your Docker environment to point to the minikube Docker service, and instructs kubectl to use the proper namespace for this sample.

    ```
    minikube ssh "sudo ip link set docker0 promisc on" && \
    eval $(minikube docker-env) && \
    kubectl config use-context sample-context
    ```


3. With Helm installed and kubectl setup to work with your Kubernetes cluster (either local or remote), you can choose between two ways of running the sample.

    **Option 1**: If you want to simply run the sample as quickly as possible and do not expect to make changes to it yourself, simply install the published helm chart:

    ```
    helm dep build . && \
    helm install . -n sample-fr-platform
    ```

    **Option 2:** If you want to work on the sample, you can use the "[skaffold](https://github.com/GoogleContainerTools/skaffold)" tool to quickly build and deploy the images:

    ```
    skaffold dev
    ```

    This will build the docker images and incorporate them into the helm templates, followed by managing the release of the chart. Any changes made to the configuration files for each docker image will be watched by skaffold, and will result in an automatic rebuild of the image followed by a redeployment into the cluster.


4. You need to add the ingress IP to your local hosts file.

    If you are using minikube, use these commands:
    ```
    grep -v rs-service.sample.svc.cluster.local /etc/hosts \
    | sudo tee /etc/hosts && \
    echo "$(minikube ip) \
        am-service.sample.svc.cluster.local \
        rs-service.sample.svc.cluster.local" \
    | sudo tee -a /etc/hosts
    ```

    If your cluster is available directly, you can use these commands instead:
    ```
    grep -v rs-service.sample.svc.cluster.local /etc/hosts \
    | sudo tee /etc/hosts && \
    echo "$( kubectl get ing -o \
        jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' ) \
        am-service.sample.svc.cluster.local \
        rs-service.sample.svc.cluster.local" \
    | sudo tee -a /etc/hosts
    ```

5. Wait for all of the pods to become ready:

    ```
    kubectl get po -n sample --watch
    ```

    When all pods report that they are in a ready state, hit Ctrl^C to exit.

6. Create sample users in your environment:

    ```
    kubectl exec -it configstore-0 /opt/opendj/scripts/make-users.sh 10
    ```

    This will create 10 users (from user.0 through user.9) in your DS repository.

7. You can access the platform by opening this URL:

    ```
    http://am-service.sample.svc.cluster.local/openam/console
    ```

    You can use amadmin / password to login as the am admin.
    You can use user.0  / password to login as a basic end-user.

8. You can now start a sample OAuth2 client from the [Example OAuth 2 Clients Project](https://github.com/ForgeRock/exampleOAuth2Clients).

9. You can remove the sample like so:

    If you started the sample with Option 1 from step 3, then stop it like so:
    ```
    helm delete --purge sample-fr-platform
    ```

    If you used Option 2, then just hit Ctrl^c to exit skaffold. It will automatically remove the running processes.

    If you are using minikube, you can remove the whole environment with this command:
    ```
    minikube delete
    ```

### Manually building the Docker images and helm package

When you are done making changes to the base configuration, you can create final docker images and helm packages with the below commands.

Build the Docker images for this sample:

    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/rs:latest rs
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/amster:latest amster
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/idm:latest idm
    docker build -t forgerock-docker-public.bintray.io/forgerock/sample-fr-platform/pg:latest pg

You can now push these to a docker registry, if that is needed.

Create the helm package:

    helm package .

You now have a file names something like fr-platform-6.5.0-SNAPSHOT.tgz that you can publish to a helm repositories. Afterwards you can follow the steps described in the "Quick Start" section, similar to what is shown in step 1.

## Connecting to your cluster

To make the internal DS cluster accessible locally:

    kubectl port-forward ds-0 2389:1389 &

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
