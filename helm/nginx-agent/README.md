# Apache web agent helm chart

Deploy nginx and a web agent.

## Prerequisites

You need to have `forgeops/docker/nginx-agent` docker image build and accessible from
your cluster

## Configuration

Before deploying this chart, make sure your AM has a web agent configuration in place.
Modify values.yaml or provide your yaml file with correct details so agent can authenticate with AM successfully.

To do so, make sure these properties match agent profile in AM:
```
agent:
  user: nginx # Agent profile name
  amServer: http://login.example.forgeops.com/ # Location of AM server
  realm: "/" # Realm in which agent is configured
```

You need to update `secrets/.password` to contain password of agent profile. The secret will be created from it and
used to install and run the agent.

## Deploy agent

Simply run `helm install --name=nginx-agent helm/nginx-agent` chart.
