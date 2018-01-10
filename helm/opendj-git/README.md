# OpenDJ Helm chart with support for git configuration.

Deploy one or more OpenDJ instances using Persistent disk claims
and StatefulSets. 

If replicas is set > 1, each new DJ node will be configured 
to replicate to the first node.  This is a very simple topology
that will only support a small number (say 3) OpenDJ nodes. It
should be acceptable for testing and small installations. 

The instance name defaults to the Helm chart deployment name. So for example 
`helm install --name configstore`  will create a stateful set configstore-0

# Git configuration

The configuration for DJ comes from a git repository. The git
repo is cloned and mounted on /git in the container. You need to set
the path to the bootstrap setup.sh script to run to configure your instance. See
the custom.yaml section below.  

Your setup.sh script can access other files (e.g. ldif files) that are relative
to its location.  See the forgeops-init repo for an example:

https://stash.forgerock.org/projects/CLOUD/repos/forgeops-init/browse/default/dj-userstore 


# custom.yaml override 

Create a custom.yaml override file to set the parameters for your deployment.
An example:


```yaml
global:
  image:
    repository: forgerock
  git:
    sshKey: xUGs5SHRjWUR...base64-encoded-private-git-key...
    repo: "ssh://git@stash.forgerock.org:7999/cloud/forgeops-init.git"
    branch: release/5.5.0
djInstance: msauthn
baseDN: "dc=openam,dc=forgerock,dc=org"
bootstrapScript: "/git/forgeops-init/default/dj-userstore/setup.sh"
 ```
    
# Notes

By default, Minikube
uses a "host path" provisioner. This may not survive Minikube 
restarts! If you are on GKE, the default provisioner will create
persistent disk volumes (PDs). 

If you are benchmarking on GKE, use an SSD storage class,
and keep in mind that PD IOPS scale based on the size of the volume.
Anecdotally, you need to allocate at least 50 GB to get equivalent
performance to a MacBook Pro with SSD.


