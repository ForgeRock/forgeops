# Change FQDN in running deployment

## Overview
Setting the FQDN in a forgeops deployment makes the following configuration changes:
* Sets the FQDN value in the product ingress files
* Sets the default DNS alias in PingAMs realm properties
* Sets the Primary URL for PingAMs default site settings
* Sets the FQDN in various fields in the end-user-ui and idm-admin-ui oauth2client configuration.  

> **WARNING** There will be some downtime between updating the ingress URL configuration and restarting the am pods to set the new FQDN values

## Assumptions
* Customer will have a running deployment with a preconfigured environment(Helm values or Kustomize overlay) that contains their initial FQDN.
* The value of the FQDN can be viewed in the PingAM's default realm properties. 
* This has been tested on a basic forgeops deployment with a single root realm.  More complex configurations may  
required additional testing.

## Steps to update the FQDN
> **NOTE** Replace `my-env` with the name of your environment(Helm values or Kustomize overlay)

### Update the environment with the new FQDN
```BASH
$ /path/to/forgeops/bin/forgeops env --env-name my-env --fqdn my.fqdn.com
```

### Update Helm deployment and monitor SSL secret update
Rerun the Helm command used to deploy your platform and point to your custom Helm values file in your environment(helm/my-env/values.yaml). Should look something like:

```BASH
helm upgrade --install identity-platform  identity-platform \
 --repo https://ForgeRock.github.io/forgeops/ \
 --version 2025.2.0 --namespace my-namespace \
 --values /path/to/forgeops/helm/my-env/values.yaml
```

A new temporary ssl secret is created with a random suffix which will contain the new certificate with the new dns name.  The output should look like:  

```BASH
$ kubectl get secrets
...
tls-myfqdn.iam.forgeops.com            kubernetes.io/tls    2      5m19s
tls-myfqdn2.iam.forgeops.com-lttj7      Opaque               1      49s
```

Use `watch kubectl get secrets` to wait until the temporary secret goes. Once the temporary secret goes, a new secret will be added that includes the new certificate.

### Update Kustomize deployment and monitor SSL secret update
```BASH
$ /path/to/forgeops/bin/forgeops apply --env-name my-env
```

A temporary ssl secret is created with a random suffix which will contain the new certificate with the new dns name.  The output should look like:  

```BASH
$ kubectl get secrets
...
tls-identity-platform.domain.local         kubernetes.io/tls   2      64s
tls-identity-platform.domain.local-5ws2m   Opaque              1      44s
```

Use `watch kubectl get secrets` to wait until the temporary secret goes. Once the temporary secret goes, the original secret will be updated with the new certificate.  

### Update AM deployment
Rolling restart the am deployment
```BASH
$ kubectl rollout restart deployment/am
deployment.apps/am restarted
```

Monitor the status of the restart
```BASH
$ kubectl rollout restart deployment/am
Waiting for deployment "am" rollout to finish: 1 old replicas are pending termination...
deployment "am" successfully rolled out> 
```

### Run adhoc amster import to update OAuth2Clients with new FQDN
If you do have a custom amster config-profile then replace `default` with your profile
```
$ forgeops amster import --env-name my-env /path/to/forgeops/docker/amster/config-profiles/default
Cleaning up amster components.
...
Deploying amster
...
Importing directory /opt/amster/config
Imported /opt/amster/config/realms/root/IdentityGatewayAgents/ig-agent.json
Imported /opt/amster/config/realms/root/Applications/iPlanetAMWebAgentService.json
Imported /opt/amster/config/realms/root/Applications/oauth2Scopes.json
Imported /opt/amster/config/realms/root/Applications/sunAMDelegationService.json
Imported /opt/amster/config/realms/root/OAuth2Clients/client-application.json
Imported /opt/amster/config/realms/root/OAuth2Clients/clientOIDC_0.json
Imported /opt/amster/config/realms/root/OAuth2Clients/end-user-ui.json
Imported /opt/amster/config/realms/root/OAuth2Clients/idm-admin-ui.json
Imported /opt/amster/config/realms/root/OAuth2Clients/idm-provisioning.json
Imported /opt/amster/config/realms/root/OAuth2Clients/idm-resource-server.json
Imported /opt/amster/config/realms/root/OAuth2Clients/oauth2.json
Imported /opt/amster/config/realms/root/OAuth2Clients/resource-server.json
Imported /opt/amster/config/realms/root/OAuth2Clients/smokeclient.json
Import completed successfully
Import done

Amster import complete.
```

## Verify FQDN has been updated
* Ensure you can access the platform UI and can login https://myfqdn.com/platform.
* Navigate to the AM UI successfully and verify that the realm DNS alias contains the new FQDN value.


