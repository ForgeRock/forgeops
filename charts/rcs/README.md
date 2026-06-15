# Helm chart for RCS

## Preparation

### Create a values.yaml

Create a values.yaml for your configuration, and update the values according to
the environment. See the defaults/examples in `charts/rcs/values.yaml`.

The WSS URL and token for the IDM endpoint:
```
idmEndpoints:
  wss: "wss://auth.example.com/openicf"
  token: "https://auth.example.com/am/oauth2/realms/root/realms/alpha/access_token"
```

The IP address for the IDM service (e.g. Identity Cloud tenant):
`tenantIp: 1.2.3.4`

The number of pods (replicas) you want to run:
`replicaCount: 2`

Adjust according to log level requirements - e.g. `DEBUG` for test systems:
```
logLevels:
  root: "DEBUG"
```

### Create secrets

The chart relies on a few secrets to connect to your environment.

Certificates to be installed in the RCS trust store - e.g. issuing CA for LDAPS
server certificates to enable connector trust. Any unique name may be used for
each certificate.

For example, if you have a directory of certificates at `/tmp/rcs-certs`, you
can create the secret like this:

`kubectl create secret generic rcs-certs --from-file=/tmp/rcs-certs`

You also need to create a secret to hold the clientId and clientSecret needed to
connect to your PIP deployment. In this example, we are using the default
clientId in AIC called RCSClient. This should be whatever you called the oauth
client in your deployment.

- clientId - The OAuth2 client ID for acquiring an access token
- clientSecret - The OAuth2 client secret for the above client ID
-
`kubectl create secret generic rcs-client-auth --from-literal=clientId=RCSClient --from-literal='clientSecret=Testing123!'`

## Install

Install the RCS Helm chart in the current namespace

`helm install rcs rcs --repo https://ForgeRock.github.io/forgeops -f my-values.yaml`

There should now be running RCS pod(s) - e.g. with 2 replicas:

```
% kubectl get pods
NAME    READY   STATUS    RESTARTS   AGE
rcs-0   1/1     Running   0          50s
rcs-1   1/1     Running   0          50s
```
