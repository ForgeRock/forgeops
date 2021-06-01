# Deploy the ForgeRock Identity Platform in an OpenShift Cluster

## Important

This README was written when OpenShift 4 and its installer were in pre-beta 
development. Most of the information in this README is likely to be out of date,
since it's primarily a compilation of workarounds. But if you understand 
OpenShift, you should be able to utilize this README. This deployment has been 
tested only on AWS, but the `openshift-install.sh` script will likely work for 
multiple providers.

## File Locations

The ForgeRock Cloud Deployment team used Kustomize and Skaffold to orchestrate 
and test deployment on OpenShift. The artifacts required to deploy the ForgeRock
Identity Platform on OpenShift are located in the `kustomize/overlay/7.0/openshift`
directory.

## Create a Red Hat developer account

Before starting, make sure you have a Red Hat developer account, and have 
obtained registry secrets.

[Create a Red Hat account.](https://developers.redhat.com/)

[Get the registry secrets](https://cloud.redhat.com/openshift/install/aws/installer-provisioned) -
use the `Download pull secrets` and `Download command-line tools` buttons.

##  Run the Installer Script

Make sure the `openshift-installer`, `oc`, `yq` and `aws` commands are in your 
path.

Create a file to contain your secrets:
```
cp cluster/openshift/env/example-secrets.yaml cluster/openshift/env/local.yaml
```

Edit the `local.yaml` file. Set the SSH public key value (`sshKey`) and Red 
Hat pull secrets (`pullSecret`). The `cluster/openshift/env/local.yaml` will be 
merged with the `cluster/openshift/installer-config.yaml` file when you run 
the installer script in the next step. 

Run the installer script. Note that running the scriopt requires nearly all 
privileges on your AWS account; see the OpenShift installer documentation: 

```                                                       
# to follow progress `less +F forgerock-openshift/.openshift_install.log`
# last two lines will be kubeadmin and password
bash bin/openshift-install.sh forgerock-openshift 
```                                                                                                                                                          

## Deploy and Run the ForgeRock Identity Platform

Running and deploying to OpenShift is slightly different than working with other
cloud providers. Skaffold deploys containers using the label and the SHA of the 
image. The runtime for OpenShift (cri-o) doesn't know how to handle that 
tagging, and will fail to pull images. There are open tickets to fix this 
incompatibility on both Skaffold and `cri-o`.

_update: this section about cri-o issues might be resolved, but a new Skaffold 
profile will need to be setup to use the openshift kustomize `kustomize/env/openshift`_

To deploy the platform on OpenShift:

1. First, run `skaffold build`, and then push to an AWS registry. It's ideal to 
   do this on a network with good upload speed.
1. Then, use `kustomize` and `oc` to deploy.

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

Configure Kustomize so that it changes the Docker image names to the names you 
created in the registry:

```
bin/openshift-configure-kustomize-images.sh
```

Now deploy:

```
oc login # user/pass should have been in the last two lines of the install output (see last line of shell script)
kustomize build kustomize/env/openshift | oc apply -f -
oc get po,sts
```

## Known Issues

There's an issue with continually re-deploying security profiles, so when 
updating, it will show errors for those files but that doesn't have any side 
effect except ugly shell output.

The following Jira issues have full details:

* [CLOUD-1565 	Investigate OpenShift deployment](https://bugster.forgerock.org/jira/browse/CLOUD-1565)
* [CLOUD-1585 	Bootstrap AWS account for OpenShift installer](https://bugster.forgerock.org/jira/browse/CLOUD-1585)
* [CLOUD-1586 	install OpenShift on AWS](https://bugster.forgerock.org/jira/browse/CLOUD-1586)
* [CLOUD-1587 	Deploy directory service to OpenShift](https://bugster.forgerock.org/jira/browse/CLOUD-1587)
* [CLOUD-1588 	Deploy rest of services to OpenShift](https://bugster.forgerock.org/jira/browse/CLOUD-1588)

The following are known issues with ForgeRock Identity Platform deployments on 
OpenShift:

* The OpenShift ingress/route controller uses HA Proxy and might need a custom 
  configuration deployed to support proper load balancing and redirects.
* The PSP currently in the repo for the UI containers isn't required anymore.
* The Secret Agent controller hasn't been tested on OpenShift.
  
