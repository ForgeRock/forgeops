# OpenShift Cluster


## Create a Red Hat developer account

[Create Red Hat account.](https://developers.redhat.com/)
[Get the registry secrets.](https://cloud.Red Hat.com/openshift/install/aws/installer-provisioned) see the `Download pull secrets` and `Download command-line tools` buttons.

You should have `openshift-installer` and `oc` in your path to proceed.


## install the openshift installer from source

We will use a recent version of the installer which uses okd 4.2 but use some private registries so a Red Hat developer account is required.

The software `yq` and `jq` is needed.
```
~/projects/forgeops2 on  CLOUD-1632-scripts-for-openshift ● ✚ ●
❯ yq --version
yq 2.7.2 # brew might install an old version...

~/projects/forgeops2 on  CLOUD-1632-scripts-for-openshift ● ✚ ●
❯ jq --version
jq-1.5-1-a5b5cbe
```

Compile the installer:
```
~/projects/golang/src/github.com/openshift
❯ git clone https://github.com/openshift/installer.git
Cloning into 'installer'...
remote: Enumerating objects: 31, done.
remote: Counting objects: 100% (31/31), done.
remote: Compressing objects: 100% (22/22), done.
remote: Total 85821 (delta 12), reused 22 (delta 9), pack-reused 85790
Receiving objects: 100% (85821/85821), 67.47 MiB | 5.14 MiB/s, done.
Resolving deltas: 100% (51936/51936), done.

~/projects/golang/src/github.com/openshift
❯ cd installer

~/projects/golang/src/github.com/openshift/installer on  master
❯ ./hack/build.sh
+ minimum_go_version=1.10
+ + go version
+ + cut -d   -f 3
+ + current_go_version=go1.12.9
+ + version 1.12.9
+ + IFS=.
+ + printf %03d%03d%03d\n 1 12 9
+ + unset IFS
+ + version 1.10
+ + IFS=.
+ + printf %03d%03d%03d\n 1 10
+ + unset IFS
+ + [ 001012009 -lt 001010000 ]
+ + LAUNCH_PATH=/home/max/projects/golang/src/github.com/openshift/installer
+ + dirname ./hack/build.sh
+ + cd ./hack/..
+ + go list -e -f {{.Dir}} github.com/openshift/installer
+ + PACKAGE_PATH=/home/max/projects/golang/src/github.com/openshift/installer
+ + test -z /home/max/projects/golang/src/github.com/openshift/installer
+ + LOCAL_PATH=/home/max/projects/golang/src/github.com/openshift/installer
+ + test /home/max/projects/golang/src/github.com/openshift/installer != /home/max/projects/golang/src/github.com/openshift/installer
+ + MODE=release
+ + git rev-parse --verify HEAD^{commit}
+ + GIT_COMMIT=596d9cf8592b9aedec683a90d75763beca06e5cd
+ + git describe --always --abbrev=40 --dirty
+ + GIT_TAG=unreleased-master-1748-g596d9cf8592b9aedec683a90d75763beca06e5cd
+ + LDFLAGS= -X github.com/openshift/installer/pkg/version.Raw=unreleased-master-1748-g596d9cf8592b9aedec683a90d75763beca06e5cd -X github.com/openshift/installer/pkg/version.Commit=596d9cf8592b9aedec683a90d75763beca06e5cd
+ + TAGS=
+ + OUTPUT=bin/openshift-install
+ + export CGO_ENABLED=0
+ + LDFLAGS= -X github.com/openshift/installer/pkg/version.Raw=unreleased-master-1748-g596d9cf8592b9aedec683a90d75763beca06e5cd -X github.com/openshift/installer/pkg/version.Commit=596d9cf8592b9aedec683a90d75763beca06e5cd -s -w
+ + TAGS= release
+ + test  != y
+ + go generate ./data
+ writing assets_vfsdata.go
+ + echo  release+
+ grep -q libvirt
+ + go build -ldflags  -X github.com/openshift/installer/pkg/version.Raw=unreleased-master-1748-g596d9cf8592b9aedec683a90d75763beca06e5cd -X github.com/openshift/installer/pkg/version.Commit=596d9cf8592b9aedec683a90d75763beca06e5cd -s -w -tags  release -o bin/openshift-install ./cmd/openshift-install
```
Create file to contain your secrets:
```
cp cluster/openshift/env/example-secrets.yaml cluster/openshift/env/local.yaml
```

Now edit `local.yaml`. Edit SSH public key value (`sshKey`) and Red Hat pull secrets `pullSecret`. `cluster/openshift/env/local.yaml` will be merged with `cluster/openshift/installer-config.yaml` before the installer is run (using `bin/openshift-install.sh`

Now run an install. This will require nearly all privileges on your AWS account (see installer docs). You should have a default profile for the AWS CLI as well.

```
# to follow progress `less +F forgerock-openshift/.openshift_install.log`
# last two lines will be kubeadmin and password
bash bin/openshift-install.sh forgerock-openshift
```


## Running forgeops


Running and deploying to OpenShift is slightly different than working with other clusters. Skaffold deploys containers using the label and the SHA of the image. The runtime for openshift (cri-o) doesn't know how to handle that tagging and will fail to pull images. There are open tickets on both Skaffold and the runtime OpenShift uses `cri-o` to fix compatability.

Deploying involves two steps:
1. run skaffold build and push to a registry in AWS
1. use kustomize and `oc` to deploy

Build images _note: ideal to do a network with good upload speed_

```
~/projects/forgeops2 on  CLOUD-1632-scripts-for-openshift ● ●
❯ eval $(aws ecr get-login --no-include-email)
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /home/max/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded

~/projects/forgeops2 on  CLOUD-1632-scripts-for-openshift ● ●
❯ skaffold build -d "048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops"
Generating tags...
 - 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/am -> 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/am:latest
 - 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/amster -> 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/amster:latest
 - 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/idm -> 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/idm:latest
 - 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-cts -> 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-cts:latest
 - 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-idrepo -> 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-idrepo:latest
Tags generated in 112.75µs
Checking cache...
 - 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/am: Not found. Building
 - 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/amster: Not found. Building
 - 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/idm: Not found. Building
 - 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-cts: Not found. Building
 - 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-idrepo: Not found. Building
Cache check complete in 2.005277988s
Starting build...
Building [048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/am]...
Sending build context to Docker daemon  8.192kB
Step 1/8 : FROM gcr.io/forgerock-io/am/pit1:7.0.0-b622db854c506fcf136f4f771ff2e38a3ddd77d4
 ---> 8a00048b399d
Step 2/8 : USER root
 ---> Using cache
 ---> b7232ff3e3fe
Step 3/8 : RUN apt-get update && apt-get install -y ldap-utils
 ---> Using cache
 ---> 29d59a11dd36
Step 4/8 : USER forgerock
 ---> Using cache
 ---> 29c6ed5eef0b
Step 5/8 : COPY --chown=forgerock:root openam /home/forgerock/openam
 ---> Using cache
 ---> b6c6e7f7955d
Step 6/8 : COPY logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes
 ---> Using cache
 ---> 76ee4acfbee2
Step 7/8 : COPY --chown=forgerock:root openam /home/forgerock/openam
 ---> Using cache
 ---> 2d1d0e0d1045
Step 8/8 : CMD ["bash", "-c", "/home/forgerock/openam/boot.sh"]
 ---> Using cache
 ---> c7d7be33fbe7
Successfully built c7d7be33fbe7
Successfully tagged 048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/am:latest
The push refers to repository [048497731163.dkr.ecr.us-east-1.amazonaws.com/forgeops/am]
4f757401c4c2: Preparing
5224c36520c7: Preparing
...etc...
```


Configure Kustomize so that it changes the docker image names to the names you created in the registry.

```
bin/openshift-configure-kustomize-images.sh
```

Now deploy

```
oc login # user/pass should have been in the last two lines of the install output (see last line of shell script)
kustomize build kustomize/env/openshift | oc apply -f -
oc get po,sts
```

There seems to be an issue with continually re-deploying security profiles, so when updating it will show errors for those files but that doesn't have any side effect except ugly shell output.

Currently it doesn't look like the route objects are being created by the openshift ingress controller. We have to check back later with newer version to see if this is back or if we need to add a custom resource for it.

Add work around route object. This doesn't configure TLS, which can be done self signed.
```
cat << EOF > /tmp/route.yaml
apiVersion: v1
items:
- apiVersion: route.openshift.io/v1
  kind: Route
  metadata:
    labels:
      app: am
    name: am
    namespace: default
  spec:
    host: default.apps.fropenshift.openshift.forgeops.com
    subdomain: ""
    to:
      kind: Service
      name: am
      weight: 100
    wildcardPolicy: None
  status:
    ingress:
    - conditions:
      host: default.apps.fropenshift.openshift.forgeops.com
      routerCanonicalHostname: apps.fropenshift.openshift.forgeops.com
      routerName: default
      wildcardPolicy: None
kind: List

oc apply -f /tmp/route.yaml
```

Tickets have full details:

* CLOUD-1565 	Investigate OpenShift deployment
* CLOUD-1585 	bootstrap AWS account for openshift installer
* CLOUD-1586 	install openshift on AWS
* CLOUD-1587 	deploy directory service to openshift
* CLOUD-1588 	deploy rest of services to openshift
