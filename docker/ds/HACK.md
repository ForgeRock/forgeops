# Developing / Hacking on DS

* Get a copy of opendj 6.0, and place it in this folder (ds/opendj.zip). 
* Start minikube:`minikube start --bootstrapper kubeadm --kubernetes-version v1.10.4 --memory 6192`
* Connect your docker command up:  `eval $(minikube docker-env)`

Build:

* Build the docker image. You can issue docker commands or use the build.sh shell script.
    * `cd forgeops/docker; ./build.sh -g ds`  - will  build an image called gcr.io/engineering-devops/ds:6.5.0
* If you just want to docker run something (to see if the image comes up)
    * `docker run -rm -it gcr.io/engineering-devops/ds:6.5.0` 
    * Or to get a bash shell into the final image:  `docker run -rm -it gcr.io/engineering-devops/ds:6.5.0 debug` 


Run Helm:

To test in minikube I am using the follow custom.yaml:

```yaml
image:
  repository: gcr.io/engineering-devops
  #pullPolicy: Always
  pullPolicy: IfNotPresent
  tag: 6.5.0

instance: userstore

replicas: 2
persistence: false
```

Deploy with:

```sh
cd helm/
helm install --name ds -f custom.yaml ds/
```

You can exec into the image and play around, etc. 
```
k get pods 
k exec userstore-0 -it bash
```

Things to note:

* The docker-entrypoint.sh relocates (copies) most folders from db/* to data/db/*. The changes in config-changes.ldif update the configuration to point to these locations using commons config.
* The secrets/ folder is added at build time. I couldn't get the CA keystore to properly sign the ssl cert using the create-keystores.sh script. I gave up on this for now and used keystore explorer. The secrets folder can get mounted by the helm chart when deployed to Kubernetes. As long as the pods all mount the same secrets, SSL will work.

