# Using an externally deployed PingDS with the Ping Identity Platform

## Objective
Deploy the Ping Identity Platform in Kubernetes but connect to an externally deployed PingDS.  
This document describes steps to use PingDS deployed in a VM external to the Kubernetes cluster  
where the platform has been deployed.  The steps could also be easily adapted for a user  
who wants to deploy PingDS in a different namespace in the same cluster or in a cluster different  
from the rest of the platform products.

## Assumptions
* The user has a local clone of the `forgeops` repo and is at the root of the `forgeops` repo.
* Have a preconfigured environment (Kustomize overlay or Helm values) using the `bin/forgeops env` command.
* Have Docker images customized and built as required and image tags updated in your environment.
* Following steps are for a single PingDS instance that is running as an Identity Store,  
  application store and token store.  Review/adapt the setup scripts for your needs.
* A static public IP address assigned to the VM.  (DNS entry to the IP address optional).  
You may have 2 VMs (idrepo and cts) requiring 2 different IPs.
* Firewall access enabled between cluster and VM. Allow tcp ports 1389,1636 and 8080.


Kustomize commands are provided for:
  * 7.4 (release/7.4-20240805) or 7.5 (release/7.5-20240618)
  * New ForgeOps: >= 2025.1.0 (Using 2025.2.1 as in the examples). 

Helm commands are provided only for ForgeOps 2025.2.1 onwards due to a previous issue  
where the PingDS  keys were deleted alongside DS.

## Prepare the Kubernetes deployment

The initial Kubernetes deployment must be made first as this will provision the SSL keypairs  
required for the external PingDS implementation.  If you are provisioning your own  SSL keypairs,  
the order can be altered as long as the SSL keypairs are configured in the  correct format and  
included in both environments.

### (Kustomize Only) Configure the platform settings for your deployment

In your local `forgeops` repo:  

**Kustomize**  
* Navigate to your custom overlay:  
  * 7.4/7.5 release branches: `kustomize/overlay/<custom-overlay>/base.yaml`. 
  * 2025.2.1: `kustomize/overlay/<custom-overlay>/base/platform-config.yaml`.  
* Add your PingDS connection strings for PingAM as follows:
  ```YAML
  apiVersion: v1
  kind: ConfigMap
  metadata:
   name: platform-config
  data:
   FQDN: "<your-fqdn>"
   AM_STORES_CTS_SERVERS: "my.public.cts1.dns.com:1636"
   AM_STORES_USER_SERVERS: "my.public.idrepo1.dns.com:1636"
  ```
* Update the PingDS SSL key-pairs with the hostnames of your PingDS servers. 
  * If using secret-agent for secret provisioning(default)
    * Copy `kustomize/base/secrets/secret-agent/ds-certificates.yaml` to `kustomize/overlay/<custom-overlay>/secrets/secret-agent/ds-certificates.yaml`
    * Update `kustomize/overlay/<custom-overlay>/secrets/secret-agent/kustomization.yaml`
      ```YAML
      resources:
      - ../../../../base/secrets/secret-agent
      - ds-certificates.yaml
      ```
  * If using Secret Generator for secret provisioning:
    * Copy `kustomize/base/secrets/secret-generator/ds-certificates.yaml` to `kustomize/overlay/<custom-overlay>/secrets/secret-generator/ds-certificates.yaml`
    * Update `kustomize/overlay/<custom-overlay>/secrets/secret-generator/kustomization.yaml`
      ```YAML
      resources:
      - ../../../../base/secrets/secret-generator
      - ds-certificates.yaml
      ```
  * Add your PingDS hostnames or DNS names, that will be used by PingDS servers to replicate between themselves,  
    to the ds-ssl-cert Certificate object's dnsNames field in `ds-certificates.yaml`.
      ```YAML
        dnsNames:
        - "*.ds"
        - "*.ds-idrepo"
        - "*.ds-cts"
        - "my-ds-hostname-1"
        - "my-ds-hostname-2"
      ```

**Helm**  
* In your custom Helm env(e.g. `helm/my-env/values.yaml`),  
  set DNS values for the following fields:  
  ```YAML
  platform:
    external_ds:
      enabled: true
      cts_hosts: my.public.cts1.dns.com:1636
      idrepo_hosts: my.public.idrepo1.dns.com:1636
  ```
* Update the PingDS SSL key-pairs with the hostnames of your PingDS servers. 
  * Edit `charts/identity-platform/ds-certificates.yaml`
  * Add your PingDS hostnames or DNS names, that will be used by PingDS servers to replicate between themselves,  
    to the ds-ssl-cert Certificate object's dnsNames field in `ds-certificates.yaml`
    ```YAML
      dnsNames:
      - "*.ds"
      - "*.ds-idrepo"
      - "*.ds-cts"
      - "my-ds-hostname-1"
      - "my-ds-hostname-2"
    ```

### Initial deploy to get PingDS secrets
You will need to retrieve the secret values generated from either the secret-agent or secret generator  
in the cluster so start by deploying the secrets

**Kustomize**:
* 7.4/7.5 release branches: `bin/forgeops install base -f <fqdn>`
* 2025.2.1: `bin/forgeops apply base --env-name <custom-overlay>`

**Helm**:  
For Helm deployments, you can only deploy the whole platform then delete PingDS later.

Run the following command after updating the namespace and Helm environment name:  
  ```BASH
  helm upgrade --install identity-platform charts/identity-platform \
  --namespace my-namespace \
  --values helm/my-env/values.yaml
  ```

### Create a custom IDM image to bake in the idrepo settings

Edit `docker/idm/resolver/boot.properties`

Update the following settings:  
```YAML
openidm.repo.host=<add your PingDS idrepo public IP or DNS here>
userstore.host=<add your PingDS idrepo public IP or DNS here>
```

Build a new IDM image:  
* 7.4/7.5 release branches: `forgeops build idm --push-to <path to image registry> --tag <custom tag>`
* 2025.2.1: `forgeops build idm --env-name <env-name> --push-to <path to image registry> --tag <custom tag>`

### Configure PingDS on a VM
Download the PingDS zip file from backstage, for the version you require, and copy to /opt directory on your VM

**Prepare opt directory**  
It is important to run PingDS in the /opt directory to ensure we can run the same setup scripts as in the container.  
Below command uses main branch(equivalent 2025.2.1) as an example. Change branch as required:
```BASH
cd /opt
git clone -b main --single-branch https://github.com/ForgeRock/forgeops.git
wget https://github.com/ForgeRock/forgeops-extras/samples/external-ds/prep-ds.sh
wget https://github.com/ForgeRock/forgeops-extras/samples/external-ds/ds-setup.sh 
chown -R <user>:<user> /opt # if running as non root user
```

**Unzip and prep opendj directory**

Edit prep-ds.sh as required to unzip the correct PingDS zip version then run the script to get the opendj folder  
ready to run the initial setup. 
```BASH
source prep-ds.sh
```

Add the following line to your shell profile  
```BASH
export PATH=${PATH}:/opt/opendj/bin
```

**Configure certificates**  
Copy the `tls.crt` certificate from the ds-ssl-keypair Kubernetes secret (base64 decoded) in your cluster into a  
file called `trust.pem` in the `/opt/opendj/truststore` directory on your VM.  

  * `kubectl get secret ds-ssl-keypair -o jsonpath='{.data.tls\.crt}' | base64 --decode > ./tls.crt`
  * Copy tls.crt to /opt/opendj/truststore/trust.pem on your VM.
  * Verify trust.pem contains certificate.
    ```BASH
    cat truststore/trust.pem 
    -----BEGIN CERTIFICATE-----
    MIIBpTCCAUugAwIBAgIQEiwdqyYiCubO7Av4hlPQ8TAKBggqhkjOPQQDAjAlMRYw
    FAYDVQQKEw1mb3JnZXJvY2sub3JnMQswCQYDVQQDEwJkczAeFw0yNDEwMTcxMTI5
    MzJaFw0yNzA0MDUxMTI5MzJaMCUxFjAUBgNVBAoTDWZvcmdlcm9jay5vcmcxCzAJ
    BgNVBAMTAmRzMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEk0EnRrkFr8+ZzpL2
    KegdbOYC6uNEfCoRKRrsnHnffnAtApoZZrNE33Yz8JVAFkeAcUgDJM84gqiz8197
    1xqzoKNdMFswHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1UdEwEB
    /wQCMAAwLAYDVR0RBCUwI4IEKi5kc4ILKi5kcy1pZHJlcG+CCCouZHMtY3RzhwQi
    Fy59MAoGCCqGSM49BAMCA0gAMEUCIQC9+4lQIX9sd348yNBUhrBzRKLghoa7QRSi
    5WRALGbIoAIgLXUJBleDLZ2BC2kaYi1UAJ0r8swatN+5c9y/08tNk5Y=
    -----END CERTIFICATE-----
    ```

Copy the `tls.crt` and `tls.key` from the ds-ssl-keypair Kubernetes secret (base64 decoded) in your cluster  
into a file called `ssl-key-pair` in the `/opt/opendj/keystore` directory on your VM.

  * `kubectl get secret ds-ssl-keypair -o jsonpath='{.data.tls\.crt}' | base64 --decode > ./tls.crt`
  * `kubectl get secret ds-ssl-keypair -o jsonpath='{.data.tls\.key}' | base64 --decode > ./tls.key`
  * `cat tls.crt tls.key >> ssl-key-pair`
  * Copy  ssl-key-pair to /opt/opendj/keystore on your VM

Copy the contents of the `ds-master-keypair` Kubernetes secret (base64 decoded) from your cluster into a  
file called `master-key` in the `/opt/opendj/keystore` directory on your VM.  Contents should contain an RSA private  
key and 2 certificates despite being the same as it is self signed.

  * `kubectl get secret ds-master-keypair -o jsonpath='{.data.tls\.key}' | base64 --decode > ./ds-master-key-tls-key`
  * `kubectl get secret ds-master-keypair -o jsonpath='{.data.ca\.crt}' | base64 --decode > ./ds-master-key-ca-cert`
  * `kubectl get secret ds-master-keypair -o jsonpath='{.data.tls\.crt}' | base64 --decode > ./ds-master-key-tls-crt`
  * `cat ds-master-key-tls-key ds-master-key-ca-cert ds-master-key-tls-crt >> master-key`
  * Copy master-key to /opt/opendj/keystore on your VM

## Setup DS
Run the customized ds-setup.sh from `forgeops-extras` repo.  
The `ds-setup.sh` provided in `forgeops-extras` is a scaled down version of the script provided in the `forgeops` repo.  
You need to update the following arguments to the setup command in that script to match the secret values deployed  
in the cluster in the `ds-passwords` secret as follows:  

Get the password values from your Kubernetes environment:
```BASH
kubectl get secret ds-passwords -o jsonpath='{.data.dirmanager\.pw}'  |base64 --decode > dirmanager.pw
kubectl get secret ds-passwords -o jsonpath='{.data.monitor\.pw}'  |base64 --decode > monitor.pw
```

Update the password values in `ds-setup.sh`:
```
--rootUserPassword =  value of dirmanager.pw base64 decoded
--monitorUserPassword = value of monitor.pw base64 decoded
```

Then run your customized `ds-setup.sh` script:
```BASH
cd /opt/opendj
./ds-setup.sh
```

**Setup profiles and indexes**

Next step is to copy the PingDS runtime setup scripts from your local `forgeops` repo to your PingDS server.  

For 7.4/7.5 release branches or earlier: 
`docker/ds/default-scripts/setup`

For 2025.2.1:
`docker/ds/runtime-scripts/ds-idrepo/setup`
`docker/ds/runtime-scripts/ds-cts/setup`

Then run the script/s.  
> **Note**  
If your are using 2025.2.1 have a single PingDS VM, then run both the ds-idrepo and ds-cts setup scripts.  
If your are using 2025.2.1 and using separate PingDS VMs then run the scripts on the relevant server.  
If you are using the 7.4/7.5 release branches, the you just need to run the single setup script on each PingDS server.


**Start PingDS server** 
```BASH
./opt/opends/bin/start-ds
```

**Change service account passwords**  
The backend secrets need to match the secrets defined in the `ds-env-secrets` secret in the cluster so that PingAM/PingIDM can  
connect to the relevant backend.  Run the following commands on your PingDS instance replacing -w "password" with the  
correct password for the backend.

Update the tokens backend with the base64 decoded password from AM_STORES_CTS_PASSWORD
```BASH
bin/ldappasswordmodify -h localhost -p 1389 -D "uid=admin" -w "password" -a "dn:uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens" -n "password"
```

Update the identities backend with the base64 decoded password from AM_STORES_USER_PASSWORD
```BASH
bin/ldappasswordmodify -h localhost -p 1389 -D "uid=admin" -w "password" -a "dn:uid=am-identity-bind-account,ou=admins,ou=identities" -n "password"
```

Update the am-config backend with the base64 decoded password from AM_STORES_APPLICATION_PASSWORD
```BASH
bin/ldappasswordmodify -h localhost -p 1389 -D "uid=admin" -w "password" -a "dn:uid=am-config,ou=admins,ou=am-config" -n "password"
```

## Complete the Kubernetes deployment
**Deploy the rest of the platform (Kustomize only)**
* 7.4/7.5 release branches: `forgeops install apps ui`
* 2025.2.1: `forgeops apply apps ui --env-name <custom-overlay>`

**Verify PingAM and PingIDM can connect to the external PingDS**. 
Check the connection in the pod logs: 
* `kubectl -f logs <am-podname>`
* `kubectl -f logs <idm-podname>`

**Cleanup the DS deployment**  
Kustomize:
* 7.4/7.5 release branches: `forgeops delete ds --force`
* 2025.2.1: `forgeops delete ds --env-name <custom-overlay> --force`

Helm:  
* In your custom Helm env(e.g. `helm/my-env/values.yaml`) disable the PingDS servers:  
  ```YAML
  ds_idrepo:
    enabled: false
  ds_cts:
    enabled: false
  ```
* Reapply the changes to remove PingDS from the deployment.
  ```BASH
  helm upgrade --install identity-platform ./ \
  --repo https://ForgeRock.github.io/forgeops/ \
  --version 2025.2.1 --namespace my-namespace \
  --values helm/my-env/values.yaml
  ```