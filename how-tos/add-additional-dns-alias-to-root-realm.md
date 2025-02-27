# How to add an additional alias to the root realm in PingAM
This How To provides instructions to configure your ForgeOps deployment with a additional DNS alias for the root realm.

## Pre-requisites
* A custom ForgeOps deployment environment created using the forgeops env command.
* A default platform FQDN configured in your env(e.g. my.first.fqdn.com)
* An additional FQDN available for the additional alias(e.g. my.second.fqdn.com)
* A custom config-profile under `docker/am` for custom config
* A PingAM release created using the forgeops image command  
<br />  

**NOTE:** In the steps below, replace any values starting `my-` with your custom values

## Update the ingress resource  
First you need to update the ingress resource in your custom env to configure the ingress controller with the additional FQDN.

### Kustomize steps
The easiest way to configure your overlay is to copy the complete `am` ingress  
definition into the `am` sub overlay in your custom overlay.

1. Create a file called `ingress.yaml` in `kustomize/overlay/my-env/am`.  
2. Copy the contents of the ingress definition from `kustomize/base/am/resources.yaml`(~L232) to the new `ingress.yaml`.
3. In `ingress.yaml` update the current host entries with your default FQDN.  

   **WARNING**: Do not update the secretName field unless you have configured a custom secret name in your environment.  
4. In `ingress.yaml` add an additional rule for your additional FQDN. See the resulting sample file below(Example FQDNs used):  

    ```YAML
    spec:
        ingressClassName: nginx
        tls:
            - hosts:
                - my.first.fqdn.com
                - my.second.fqdn.com
              secretName: tls-identity-platform.domain.local
        rules:
            - host: my.first.fqdn.com
              http:
                paths:
                  - path: /am
                    pathType: Prefix
                    backend:
                      service:
                        name: am
                        port:
                          number: 80
            - host: my.second.fqdn.com
              http:
                paths:
                  - path: /am
                    pathType: Prefix
                    backend:
                      service:
                        name: am
                        port:
                          number: 80
   ```
5. Update the kustomization.yaml file in your custom env:  
   Add `- path: ingress.yaml` under `patches:` and comment out the ingress-fqdn patch as follows:  
    ```YAML
    patches:
    - path: deployment.yaml
    - path: ingress.yaml
    # - path: ingress-fqdn.yaml
    #   target:
    #     group: networking.k8s.io
    #     version: v1
    #     kind: Ingress
    #     name: am
    ```

6. Deploy your Kustomize environment

## Helm
1. Open your custom env e.g. `helm/my-env/values.yaml`.  
2. Under platform.ingress.hosts, add your additional FQDN as follows
    ```YAML
    platform:
    ingress:
        hosts:
        - my.first.fqdn.com
        - my.second.fqdn.com
    ```
3. Deploy your Helm environment

## Configuring PingAM
Create a custom PingAM image which includes the additional FQDN as a DNS alias for the root realm.

1. Login to the PingAM console.
2. In realm properties, add your additional FQDN to the `DNS Aliases` field.
3. From your cmdline, export the PingAM config where `--release-name` must match the version of PingAM that you are using and replace `my-profile` with the name of your config-profile.
  ```
  bin/forgeops config export am my-profile --release-name 7.5.0
  ```
4. From your exported config, add your additional FQDN to the aliases list.
   * Edit `docker/am/config-profiles/<custom-config-profile>/config/services/global/realms/root.json`
   * Append additional FQDN to end of `data.aliases` list as follows:
    ```
    "aliases" : {
      "$list" : "&{am.server.hostnames|&{am.server.fqdn},am,am-config,my.second.fqdn.com}"
    }
    ```
5. Build a new custom PingAM image:  
   ```BASH
   ./bin/forgeops build am --config-profile my-profile --env-name my-env --push-to my-repo --tag my-tag
   ```

## Redeploy PingAM

### Redeploy Ping AM with Helm

`helm upgrade -i identity-platform charts/identity-platform --repo https://ForgeRock.github.io/forgeops/ \
 --version 2025.1.1 --values helm/my-env/values.yaml`

### Redeploy Ping AM with Kustomize

`./bin/forgeops apply -e my-env am`

## Verify access to serverinfo endpoint with additional FQDN

Run the following command:

`curl "https://my.second.fqdn.com/am/json/realms/root/serverinfo/*"`

Output should look like:

```BASH
{"_id":"*","_rev":"-485253810","protectedUserAttributes":["telephoneNumber","mail"],"cookieName":"iPlanetDirectoryPro","secureCookie":true,"forgotPassword":"false","forgotUsername":"false","kbaEnabled":"false","selfRegistration":"false","lang":"en-US","successfulUserRegistrationDestination":"default","socialImplementations":[],"referralsEnabled":"false","zeroPageLogin":{"enabled":false,"refererWhitelist":[],"allowedWithoutReferer":true},"realm":"/","xuiUserSessionValidationEnabled":true,"fileBasedConfiguration":true,"userIdAttributes":[]}%
```

If there is an issue with the setup, the output will look like:
```BASH
{"code":400,"reason":"Bad Request","message":"Realm not found"}%
```



