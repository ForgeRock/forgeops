# OpenShift Cluster

**NOTICE** This README was written when OpenShift 4 and the installer were in pre-beta development. Most of this is likely to be out of date since they were mostly work arounds and you should understand most of the tools to utilize this README.

The important changes to run on OpenShift are located in `kustomize/env/openshift`

Known Issues with OpenShift
* Ingress/Route controller for OpenShift uses HA Proxy and might need a custom configuration deployed to support proper load balancing and re directs
* The PSP currently in the repo for the UI containers isn't required anymore
* Secret Agent controller hasn't been tested on OpenShift 

_Tested on AWS only but the os-install works for multiple providers_

## Create a Red Hat developer account

[Create Red Hat account.](https://developers.redhat.com/)
[Get the registry secrets.](https://cloud.Red Hat.com/openshift/install/aws/installer-provisioned) see the `Download pull secrets` and `Download command-line tools` buttons.

You should have `openshift-installer` and `oc` in your path to proceed.


##  Quick script

You should have `yq` and `aws` in your path to proceed with the script.

Create file to contain your secrets:
```
cp cluster/openshift/env/example-secrets.yaml cluster/openshift/env/local.yaml
```

Now edit `local.yaml`. Edit SSH public key value (`sshKey`) and Red Hat pull secrets `pullSecret`. `cluster/openshift/env/local.yaml` will be merged with `cluster/openshift/installer-config.yaml` before the installer is run using `bin/openshift-install.sh`

Run script:

```                                                                                                                                                          
# to follow progress `less +F forgerock-openshift/.openshift_install.log`                                                                                    
# last two lines will be kubeadmin and password                                                                                                              
bash bin/openshift-install.sh forgerock-openshift                                                                                                            
```                                                                                                                                                          

Note: This will require nearly all privileges on your AWS account (see openshift installer docs).

## Running forgeops

_update: this section about cri-o issues might be resolved, but a new skaffold profile will need to be setup to use the openshift kustomize `kustomize/env/openshift`_
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
❯ skaffold build -d "ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops"
Generating tags...
 - ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/am -> ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/am:latest
 - ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/amster -> ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/amster:latest
 - ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/idm -> ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/idm:latest
 - ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-cts -> ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-cts:latest
 - ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-idrepo -> ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-idrepo:latest
Tags generated in 112.75µs
Checking cache...
 - ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/am: Not found. Building
 - ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/amster: Not found. Building
 - ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/idm: Not found. Building
 - ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-cts: Not found. Building
 - ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/ds-idrepo: Not found. Building
Cache check complete in 2.005277988s
Starting build...
Building [ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/am]...
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
Successfully tagged ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/am:latest
The push refers to repository [ACCT_ID.dkr.ecr.us-east-1.amazonaws.com/forgeops/am]
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

```

Tickets have full details:

* CLOUD-1565 	Investigate OpenShift deployment
* CLOUD-1585 	bootstrap AWS account for openshift installer
* CLOUD-1586 	install openshift on AWS
* CLOUD-1587 	deploy directory service to openshift
* CLOUD-1588 	deploy rest of services to openshift
