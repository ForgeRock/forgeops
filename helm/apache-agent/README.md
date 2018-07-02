# Apache web agent helm chart
This chart provides the way how to deploy apache 2.4 along with web agent configured

## Prerequisites
You need to have `forgeops/docker/apache-agent` docker image build and accessible from
your cluster

## Configuration
Before deploying this chart, make sure your AM has a web agent configuration in place.
Modify values.yaml or provide your yaml file with correct details so agent can authenticate with AM successfuly.


To do so, make sure these properties match agent profile in AM:
```
agent:
  user: apache # Agent profile name
  password: password # Agent password
  amServer: http://openam.example.forgeops.com/openam # Location of AM server
  realm: "/" # Realm in which agent is configured
```

## Deploy agent
Simply run `helm install --name=apache-agent helm/apache-agent` chart.
