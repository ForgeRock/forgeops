# frconfig - Manage configuration for the ForgeRock platform components

This chart creates Kubernetes config maps and secrets needed to clone platform configurations
from a git repository. It also optionally creates certificate requests for SSL.

This is a prerequisite chart that must be deployed before other charts such as openam, openig, amster, and openidm.

## values.yaml

The defaults in values.yaml clones the public (read only) [forgeops-init](https://github.com/ForgeRock/forgeops-init) repository. This 
is a bare bones starter repository with a minimal platform configuration.

To use a different git repository, you must create a custom values.yaml with your git details.
Note that private git reposities must use a git url of the form `git@github.com....`. 
Git https urls can only be cloned if they are public.

A sample custom.yaml is shown below:

```yaml
git:
  # git repo to clone.
  repo: "git@github.com:Acme/cloud-deployment-config.git"
  branch: mybranch
# Usually you do not need to change config.name. See the comments below for more information.
# config:
#   name: frconfig
```

## git secret

A dummy ssh secret `id_rsa` is stored in the `frconfig` secret. If you need ssh access to your git repository
you must replace this secret with a real ssh key. There are two ways to do this: You can replace the contents of the file `secrets/id_rsa` with your ssh key, or alternatively you can use kubectl commands to replace the dummy secret with the 
real value. For example:


```shell
# Generate your own id_rsa and id_rsa.pub keypair, according to the instructions on github or stash,
# then run the following commands:
kubectl delete secret frconfig
kubectl create secret generic frconfig --from-file=id_rsa
```

Note the secret file name (the key in the secret map) *must* be id_rsa.  This is the private key that has permissions to clone and/or update your repository (the public part of this key is uploaded to your github or stash repository).

The id_rsa file must be kept private. Do not check this file into source control.

## Configuration per product

This project uses a single git repository that contains configuration for all products. If you want to use a strategy of a configuration repository per product, you can deploy multiple instances of this chart, each with a different name for `config.name`.

The value for `config.name` is significant, as other
charts reference this value. Products default `config.name` to "frconfig", but this can be overridden by helm.

As an example, to create a custom configuration for openig, use the following procedure:

* Create an appropriate values.yaml with `git` settings for your repository. Set config.name to "my-ig-config"
* Deploy this chart `helm install -f values.yaml frconfig`
* Replace the dummy ssh secret with your id_rsa value. See the section above. Note the secret name is now `my-ig-config`
* Deploy the openig chart, overriding the configuration name:  `helm install --set config.name=my-ig-config openig`

## Certificates

cert-manager is used to provision a wildcard SSL certificate of the form `wildcard.$namespace.$domain`.  The default in values.yaml
configures cert-manager to issue self signed certificates (the CA issuer). You can  configure cert-manager to issue certificates
using  Let's Encrypt. Please refer to the [cert-manager](https://github.com/jetstack/cert-manager) project.
