# Sample Helm chart to deploy OpenIDM

This chart depends on the postgresql chart for the OpenIDM repository database. The
postgresql chart has been kept separate so that OpenIDM can be started / stopped
independent of the database. 

# Design

The chart assumes that the OpenIDM configuration files (/conf/*.json, scripts/* , etc.) are 
mounted on the OpenIDM container as a volume at runtime.  This is an alternative
to making an immutable Docker container with the configuration baked into the container. 

# Development Example

Fork and clone the following example configuration: 
https://github.com/ForgeRock/forgeops-init. 

Assume this is saved to your home directory at ~/forgeops-init.

Create a custom.yaml file that overrides any required values found in the chart openidm/values.yaml. Please 
see the comments in values.yaml to understand what you can override.

Deploy PostgreSQL and OpenIDM to Minikube:
```
helm install --name postgresql postgresql
sleep 60 
helm install --name openidm -f custom-openidm.yaml openidm 

```

You should be able to access OpenIDM at the ingress defined path:  https://openidm.example.com

Any changes you make in the OpenIDM admin GUI will be captured in your cloned directory ~/forgeops-init.
Try making changes, and running `git status`.

When you are happy with the configuration, commit and push your changes.

# Production Mode

Edit custom.yaml file to pull the configuration from git instead of 
the local file system. For example:

```yaml
stackConfigSource:
  gitRepo:
    repository: https://stash.forgerock.org/scm/cloud/forgeops-init.git
    revision: HEAD
```

Note that the git repo must be hosted somewhere that the pod can access.

Deploy using the same Helm commands as with local mode. Each pod will clone the git repo
before starting OpenIDM. 

Note that any admin configuration changes you make will *not* be saved. Once the pod
is restarted the configuration will be pulled again from git. 

# Ingress

There is an ingress controller defined for the fqdn defined in values.yaml.  If you are on Minikube,
put the IP address returned by `minikube ip` or  `kubectl get ingress` in /etc/hosts.

For example:

192.34.90.89 openidm.example.com 

Then you can browse to:
https://openidm.example.com

If you are on Minikube you can also access the service via its NodePort:

`minikube service openidm-openidm`

# Example commands

To deploy

helm install --name openidm -f my-values.yaml openidm

To delete

helm delete --purge openidm 

To scale up the number of OpenIDM replicas

kubectl scale --replicas=2 deployment/openidm-openidm


