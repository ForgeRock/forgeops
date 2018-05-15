# frconfig - Manage configuration for the ForgeRock platform components

This chart is responsible for fetching configuration to a shared
persistent volume that is mounted by other pods. It must be running
*before* any other components can be deployed.

The shared PVC *must* be a read-write-many volume type. NFS is a popular option here, but
any read-write-many volume will work.

The script ../../bin/create-nfs-provisioner provides a sample NFS server + dynamic volume provisioner that
is suitable for this purpose.

## values.yaml

The defaults provided in values.yaml will clone the "public" forgeops-init git repository. This is a bare bones
starter repository with a minimal platform configuration. 

If you want to use a custom configuration, create a custom.yaml file that overrides the defaults. A sample
is shown below:

```yaml
git:
  # git repo to clone.
  repo: "git@github.com:Acme/cloud-deployment-config.git"
  branch: master
  # Name of a secret that contains a key "id_rsa"
  # The secret contains the git ssh key that has permissions to clone and/or update the git repo.
  sshSecretName: "git-ssh-key"
```

If you use a custom git repository make sure you create an ssh secret that contains a key `id_rsa`. This is the private key that has permissions to clone and/or update your repository (the public part of this key is uploaded to your github or stash repository).  Set the sshSecretName to the name of this secret. 

## Configuration per product

This project uses a single git repository that contains configuration for all products. If you want to use a strategy of a configuration repository per product, you can deploy multiple instances of this chart. For each instance you must customize:

* git.repo - The custom git repository to clone.
* git.sshSecretName - must be set to the git ssh secret that can clone your repository.
* storage.claim - the name of the PVC volume claim that holds the configuration and is mounted by each product pod. The default is `frconfig`.  You can set the
 claim name for each product in the values.yaml overrides. Just ensure the same claim name is used for
 the `storage.claim` in this chart, and the products `config.claim` value. For example, to deploy IDM use `helm install --set config.claim=idm openidm`.
