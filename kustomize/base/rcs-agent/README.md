# RCS Agent

The RCS Agent is a _smart_ websocket proxy between any number of IDM and Remote Connector
Server (RCS) instances.

Primary goals and features are to:
- Require a single connection URL from an RCS instance, which eases configuration
- Allow IDM and RCS instances to connect in any order
- Inform clients of network connection loss and graceful shutdown
- Restart quickly for minimum downtime
- Supports both OAuth 2.0 tokens (AM) and basic authentication with RCS
- Supports basic authentication with IDM
- Supports SSL/TLS termination

## Configuration in ForgeOps

The RCS Agent is available in all ForgeOps profiles that also include the `admin-ui` service.
One may set `RCS_AGENT_ENABLED="true"` in the `platform-config` `ConfigMap`.

This has the effect of:
- IDM will enable sync/recon retries, when websocket network connectivity fails

## RCS Agent Configuration

See the `rcs-agent/configmap.yaml` for configuration properties and `logging.properties`.

Changes made there may need to be replicated in the IDM and RCS configurations detailed below.

## IDM Configuration

`admin-ui` can generate a `conf/provisioner.openicf.connectorinfoprovider.json` file similar to
the following, which relies on some environment variables provided by ForgeOps:

```shell script
{
    "connectorsLocation" : "connectors",
    "remoteConnectorServers" : [
        {
            "useAgent" : true,
            "name" : "connectorserver",
            "displayName" : "connectorserver",
            "webSocketConnections" : {
                "$int" : "&{RCS_AGENT_WEBSOCKET_CONNECTIONS|1}"
            },
            "connectionGroupCheckInterval" : {
                "$int" : "&{RCS_AGENT_CONNECTION_GROUP_CHECK_SECONDS|900}"
            },
            "houseKeepingInterval" : {
                "$int": "&{RCS_AGENT_CONNECTION_CHECK_SECONDS}"
            },
            "newConnectionsInterval" : {
                "$int": "&{RCS_AGENT_CONNECTION_TIMEOUT_SECONDS}"
            },
            "host": "&{RCS_AGENT_HOST}",
            "port": {
                "$int": "&{RCS_AGENT_PORT}"
            },
            "websocketPath": "&{RCS_AGENT_PATH}",
            "principal": "&{RCS_AGENT_IDM_PRINCIPAL}",
            "key": "&{RCS_AGENT_IDM_SECRET}",
            "useSSL": {
                "$bool": "&{RCS_AGENT_USE_SSL}"
            }
        }
    ]
}
```

## IDM Environment Variables

IDM acts as a websocket client that connects to the RCS Agent, and requires client configuration.
The IDM environment variables, set by ForgeOps, which are related to the RCS Agent are:

- `RCS_AGENT_HOST`
  - hostname
- `RCS_AGENT_PORT`
  - port
- `RCS_AGENT_PATH`
  - path for IDM to connect to (e.g., `/idm`)
- `RCS_AGENT_USE_SSL`
  - use SSL/TLS when connecting (RCS Agent requires truststore config)
- `RCS_AGENT_IDM_PRINCIPAL`
  - Username for basic authentication
- `RCS_AGENT_IDM_SECRET`
  - Password for basic authentication
- `RCS_AGENT_WEBSOCKET_CONNECTIONS`
  - Number of websocket connections (group) to open between IDM and the RCS Agent. One (1) may be enough.
- `RCS_AGENT_CONNECTION_GROUP_CHECK_SECONDS`
  - Number of seconds between websocket-group connection checks (900 seconds is default)
- `RCS_AGENT_CONNECTION_CHECK_SECONDS`
  - Number of seconds between network connection checks
- `RCS_AGENT_CONNECTION_TIMEOUT_SECONDS`
  - Number of seconds for connection establishment timeout
- `OPENIDM_ICF_RETRY_ENABLED`
  - Enables sync/recon operation retries when websocket connections lost
  - Not enabling this feature will simply cause IDM sync/recon to consider lost network connections as an error
  - This must be enabled for the following environment variables to have any effect
- `OPENIDM_ICF_RETRY_UPDATES_ENABLED`
  - Enables retry for update/patch operations, which may not be safe unless
    connector updates are idempotent
- `OPENIDM_ICF_RETRY_DELAYSECONDS`
  - Delay, in seconds, before each retry
- `OPENIDM_ICF_RETRY_MAXRETRIES`
  - Maximum number of retries per operation
- `OPENIDM_ICF_RETRY_MAXRETRIES`
  - Maximum number of retries per operation

## RCS Configuration

Example `openicf/conf/ConnectorServer.properties` that uses basic authentication:

```shell script
# trust a self signed SSL certificate
connectorserver.trustStoreFile=/path/to/openicf/security/truststore.pkcs12
connectorserver.trustStoreType=PKCS12
connectorserver.trustStorePass=changeit

# URL for RCS Agent public ingress (there MUST be only one URL on this line)
connectorserver.url=wss://default.iam.example.com/rcs

# IMPORTANT: each RCS instance needs a unique Host ID
connectorserver.hostId=RCS_01

# must match "name" in IDM conf/provisioner.openicf.connectorinfoprovider.json
connectorserver.connectorServerName=connectorserver

# ping-pong interval in seconds, used for diagnostic reasons and keep-alive (0 turns this off)
connectorserver.pingPongInterval=0

# number of websocket connections between RCS and RCS Agent (use more than 1 when connectionTtl enabled)
connectorserver.webSocketConnections=3
connectorserver.maxWebSocketConnections=4

# number of seconds before closing and rotating websockets (0 turns this off)
connectorserver.connectionTtl=300

# number of seconds between network connection checks
connectorserver.housekeepingInterval=5

# number of seconds for connection establishment timeout
connectorserver.newConnectionsInterval=10

# basic auth credentials
connectorserver.principal=rcsPrincipal
connectorserver.password=YG7gXOTVNq0ddoR6R8oSmJgniqecOIKU

# bearer token auth
#connectorserver.tokenEndpoint=https://default.iam.example.com/am/oauth2/access_token?realm=alpha
#connectorserver.clientId=rcsClientId
#connectorserver.clientSecret=rcsClientSecret
#connectorserver.scope=fr:idm:*

connectorserver.loggerClass=org.forgerock.openicf.common.logging.slf4j.SLF4JLog
```

`connectorserver.password` can be obtained via:

```shell script
$ ./bin/print-secrets.sh 

...

Passwords for RCS Agent connectivity:

WzJn1IUyzVYy5jjk7F7Zfc5Cw4qwkOpd (rcs-agent IDM secret)
YG7gXOTVNq0ddoR6R8oSmJgniqecOIKU (rcs-agent RCS secret)
```

Import self-signed SSL certificate into RCS truststore:

```shell script
# save SSL certificate
openssl s_client -connect default.iam.example.com:443 2>/dev/null </dev/null | \
 sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \
 > /path/to/openicf/security/ssl_cert.pem

# import SSL certificate
keytool \
 -importcert \
 -storetype PKCS12 \
 -alias ssl-server-cert \
 -keystore /path/to/openicf/security/truststore.pkcs12 \
 -storepass changeit \
 -file /path/to/openicf/security/ssl_cert.pem \
 --no-prompt
```

## Logs

You will see that both RCS and IDM connected, in the logs, when the configuration is correct.

```shell script
$ kubectl logs -f rcs-agent-859f478f9b-btqkv
VM settings:
    Max. Heap Size (Estimated): 396.38M
    Using VM: OpenJDK 64-Bit Server VM

Jan 29, 2021 5:53:40 PM org.forgerock.openicf.framework.agent.AgentServer start
INFO: Agent starting :8080
Jan 29, 2021 5:55:56 PM org.forgerock.openicf.framework.agent.websocket.AuthorizationHandler channelRead
INFO: RCS connected: RCS_01:connectorserver
Jan 29, 2021 6:02:26 PM org.forgerock.openicf.framework.agent.websocket.AuthorizationHandler channelRead
INFO: IDM connected: a15682ff-6e56-4b68-a8e1-6eb8d719a103:connectorserver
```

## Legal

Copyright 2021 ForgeRock AS. All Rights Reserved.

Use of this code requires a commercial software license with ForgeRock AS.
or with one of its affiliates. All use shall be exclusively subject
to such license between the licensee and ForgeRock AS.