# External DS sample

This kustomization demonstrates how to use an external DS instance for the ds-idrepo service
instead of the in-cluster instance.

This sample assumes you have deployed an external 6.5 DS instance on a traditional VM, and that
you have network connectivity to that VM on port 1389. To setup the external DS instance,
follow the [ForgeRock Directory Service 6.5 documentation](https://backstage.forgerock.com/docs/ds/6.5). A sample
setup script for demonstration purposes is provided below.

Edit the [external-ds.yaml](external-ds.yaml) file and replace the IP address in that file with the IP address
of your external instance. If you are using a VPC, ensure that your Kubernetes cluster has connectivity to
that IP address, and that port 1389 is open.

The sample can be deployed using `skaffold -f skaffold-6.5.yaml -p external-ds dev`. The sample is the same as the `6.5/example` deployment
with the exception that the internal ds-idrepo instance is not deployed. The
sample does not deploy postgres or IDM by default, but you can add these back in by editing [kustomization.yaml](kustomization.yaml).


## Sample external DS script

The script below can be used to create a DS instance on a VM. It is provided for demonstration purposes only. In production
only ldaps should be used, and the passwords should be changed from the defaults.

```bash
!/usr/bin/env bash
unzip DS-6.5.2.zip
cd opendj
PORT_DIGIT=1
DSHOST=localhost
./setup directory-server \
    --rootUserDn "cn=Directory Manager" \
    --rootUserPassword password \
    --monitorUserPassword password \
    --hostname ${DSHOST} \
    --adminConnectorPort ${PORT_DIGIT}444 \
    --ldapPort ${PORT_DIGIT}389 \
    --enableStartTls \
    --ldapsPort ${PORT_DIGIT}636 \
    --httpPort ${PORT_DIGIT}8080 \
    --httpsPort ${PORT_DIGIT}8443 \
    --profile am-cts:6.5.2 \
    --set am-cts/amCtsAdminPassword:password \
    --set am-cts/tokenExpirationPolicy:ds \
    --profile am-identity-store:6.5.2 \
    --set am-identity-store/amIdentityStoreAdminPassword:password \
    --profile am-config:6.5.2 \
    --set am-config/amConfigAdminPassword:password \
    --profile idm-repo:6.5.2 \
    --acceptLicense
```
