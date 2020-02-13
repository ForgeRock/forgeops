# Forgeops CDK Toolbox

Deployment creates a container that hosts an in-cluster development toolbox for building and deploying the ForgeRock platform on Kubernetes.


## Requirements

* A cluster that supports [in cluster builds via kaniko](https://github.com/GoogleContainerTools/kaniko#running-kaniko-in-a-kubernetes-cluster) _hint: `bin/gke-cluster-admin.sh` will configure a GCP project for kaniko builds_
* a kaniko secret (for registry pushes)
* an cluster-admin account to deploy and work with the toolbox
* kubectl


## Installing

By default we're expecting to work in the namespace of `default` (an easy change but not a one liner).

Simple example w/ the default configuration:
```
kustomize build github.com/forgerock/forgeops//kustomize/base/toolbox/ | k apply -f -
```

Change the namespace deployment, and further kustomization of the workspace

```
❯ alias k=kubectl
❯ cat <<KUSTOMIZATION >kustomization.yaml
namespace: my-namespace
resources:
- github.com/ForgeRock/forgeops//kustomize/base/toolbox/
patches:
  - patch: |-
      kind: Deployment
      metadata:
        name: toolbox
      spec:
        template:
          spec:
            containers:
              - name: toolbox
                env:
                - name: FR_NAMESPACE
                  value: my-namespace
                - name: FR_SUBDOMAIN
                  value: iam
                - name: FR_DOMAIN
                  value: example.com
                - name: FR_FORK
                  value: https://github/maxres-fr/forgeops.git
                - name: FR_DOCKER_REPO
                  value: gcr.io/engineering-devops
    target:
      kind: Deployment
      name: toolbox
KUSTOMIZATION

❯ kustomize build . | k apply -f -
serviceaccount/forgeops-cdk-account created
clusterrole.rbac.authorization.k8s.io/forgeops-cdk-developer-role created
clusterrolebinding.rbac.authorization.k8s.io/forgeops-cdk-binding created
deployment.apps/forgeops-cdk-toolbox created
persistentvolumeclaim/forgeops-cdk-storage-claim created
```

## Using the toolbox

Once the toolbox is deployed, utilizing the toolbox requires an exec into the pod and:
1. Run the bootstrap script to set up the workspace (set up git fork, docker registry and ssh key for pushing to your repo)
2. Add ssh key to to your repo
3. Run the dev build and deploy script
```
❯ k exec -it deployment.apps/forgeops-cdk-toolbox tmux
             .
        ...... ..
      ......  .ll'
     ......  .looo,
    ......  ,loooc.
   ......  ;ooooc. ;:
  ...... .:oooo; .:oo;         ........                                      .........                       ..
 .....  .loooo, .looooc.       ..        ......   .....  .........  .......  ...    ...  .......    .......  ..   ..   .
        :oooo, ,ooooooo:       .......  ..    ... ...   ...    ... ...   ... ...   .... ...    ..  ..        ......
 ...... .col. ,ooooooo:        ..       ..    ... ...    ..    ... ...       ...  ...   ...    ..  ..        ... ...
  ......  ,. ;ooooooo;         ..        ......   ...     ........   ......  ...    ..    ......    .......  ..   ...
   ......   :ooooooo,                                          ..
    ......  .looooo,
     ......  ,oooo;
Welcome to the Forgeops toolbox!

You'll find a recent clone of the ForgeOps git repository in the current working directory.

You should begin by bootstrapping your workspace using the boostrap-project.sh tool.

Example:
$ bootstrap-project.sh run-bootstrap

More:
$ bootstrap-project.sh -h

forgeops@forgeops-cdk-toolbox-7b86f78b77-tchrv:/opt/workspace$
forgeops@forgeops-cdk-toolbox-7b86f78b77-tchrv:/opt/workspace$ bootstrap-project.sh -r gcr.io/engineering-devops -f https://github.com/maxres-fr/forgeops.git run-bootstrap
# note at somepoint you will be prompted for a password for your SSH key.
```

The toolbox contains tools for working with Skaffold and Kustomize. It also contains vim as well as some debugging tools.

# Security Notes

* The toolbox requires privileges to deploy within a cluster. These privileges are similar to those of a cluster administrator.
* Please be aware that the toolbox runs with escalated Kubernetes API privileges (for deploying)
* If you add the generated ssh key from the toolbox to a repo keep in mind that anyone with cluster access could get a hold of that key. Its safer to not to add it, and copy the repo to your localhost then push from there. e.g. `kubectl cp toolboxpod:/opt/workspace/forgeops /tmp/myforgeopscopy; cd /tmp/myforgeopscopy; git push origin master;`
