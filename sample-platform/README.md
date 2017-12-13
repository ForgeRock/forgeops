# Full Stack Sample

This is a sample project demonstrates one way to use four components of the ForgeRock Identity Platform (AM, DJ, IDM and IG). In particular, it shows how the AM policy engine can be used to control authorization for IDM, by using filters in IG.

Docker and Kubernetes are used to automate the deployment of this sample. It is designed to run primarily in Minikube, and it is intentionally oversimplified in terms of its Kubernetes configuration. This sample may be useful to show the minimum necessary Kubernetes configuration, but it should not be considered a template for a production deployment. Refer to the other areas of forgeops for production-ready templates.

## Only needed once per machine:

    minikube start --insecure-registry 10.0.0.0/24 --memory 4096
    echo "`minikube ip` idm-service.sample.svc.cluster.local am-service.sample.svc.cluster.local" >> /etc/hosts
    eval $(minikube docker-env)
    kubectl config set-context sample-context --namespace=sample --cluster=minikube --user=minikube
    kubectl config use-context sample-context

Use the forgeops project to build local docker images within your minikube environment:

    cd forgeops/docker
    mvn

Build the Docker images for this sample:

    docker build -t am:fullstack am
    docker build -t amster:fullstack amster
    docker build -t ig:fullstack ig
    docker build -t idm:fullstack idm

    kubectl create namespace sample

    kubectl create secret generic social-credentials \
        --from-literal=IDP_FACEBOOK_CLIENTID=$IDP_FACEBOOK_CLIENTID \
        --from-literal=IDP_FACEBOOK_CLIENTSECRET=$IDP_FACEBOOK_CLIENTSECRET

    kubectl apply -f .

Monitor the pods as they come up:

    kubectl logs -f dj-0
    kubectl logs -f dj-1
    kubectl logs -f am
    kubectl logs -f amster
    kubectl logs -f ig
    kubectl logs -f idm

Now the environment should be available at http://idm-service.sample.svc.cluster.local

To export changes made to AM:

    kubectl exec -it amster /opt/amster/amster
      connect http://am-service.sample.svc.cluster.local/openam -k /var/run/secrets/amster/id_rsa
      export-config --path /tmp/export
      :quit

    kubectl cp amster:/tmp/export amster/config


To export changes made to IDM:

    kubectl cp idm:/var/openidm/conf conf

Review changes to config using git diff. Remove all untracked files with this command:

    git clean -fdx

Be sure to rebuild your amster image afterwards:

    docker build -t amster:fullstack amster

To destroy the environment:

    kubectl delete namespace sample
