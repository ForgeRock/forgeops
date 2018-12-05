# Apache web agent helm chart

Deploy apache 2.4 along with web agent configured

## Prerequisites

You need to have `forgeops/docker/apache-agent` docker image build and accessible from
your cluster

## Configuration

Before deploying this chart, make sure your AM has a web agent configuration in place.
Modify values.yaml or provide your yaml file with correct details so agent can authenticate with AM successfully.

To do so, make sure these properties match agent profile in AM:
```
agent:
  user: apache # Agent profile name
  amServer: http://openam.example.forgeops.com/ # Location of AM server
  realm: "/" # Realm in which agent is configured
```

You need to update `secrets/.password` to contain password of agent profile. Secret will be created from it and
used to install and run the agent. 

## Deploy agent

Simply run `helm install --name=apache-agent helm/apache-agent` chart.
