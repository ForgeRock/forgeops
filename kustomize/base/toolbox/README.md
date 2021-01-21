# Forgeops CDK Toolbox

This deployment creates a container that hosts an in-cluster development toolbox
you can use to build and deploy the ForgeRock Identity Platform on Kubernetes.
The toolbox contains tools for working with Skaffold and Kustomize. It also 
contains the Vim editor and some debugging tools.


## Requirements

* A cluster that supports 
  [in-cluster builds using Kaniko](https://github.com/GoogleContainerTools/kaniko#running-kaniko-in-a-kubernetes-cluster) _hint: `bin/gke-cluster-admin.sh` will configure a GCP project for kaniko builds_
* A Kaniko secret (for registry pushes)
* A cluster administrative account that lets you deploy the toolbox and work 
  with it
* The `kubectl` command


## Installing

We provide a simple installer script that you can run standalone, with no 
dependencies on the forgeops repository. The script generates a Kustomize 
file in the `forgeops-toolbox` directory, then deploys the toolbox.

For example:

```
curl -o toolbox -L https://raw.githubusercontent.com/ForgeRock/forgeops/master/bin/toolbox
# using defaults configure, deploy, and set the remote for the forked copy of the ForgeOps repo
bash toolbox -f https://github.com/mygithuborg/forgeops.git all
```

If you want to change the default configuration. run the 
`toolbox -h` command to explore available options.

## Using the Toolbox

To use the toolbox after it's been deployed:

1. Run the `kubectl exec` command to access the toolbox pod.
1. In the toolbox pod, run the `bootstrap-project.sh` script to set up a 
   workspace. This script creates a Git fork and identifies the Docker registry
   you want to push images to. You'll need to provide your SSH key when you
   run this script.
1. Run the dev build and deploy script.

For example:
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

# Security Notes

* The toolbox requires privileges, similar to a cluster adminsitrator's 
  privileges, to deploy within a cluster.
* The toolbox runs with escalated Kubernetes API privileges (for deploying).
* If you add the generated SSH key from the toolbox to a Git repository, keep in 
  mind that anyone with cluster access could get the key. It's safer to not to 
  add it to the repository. Instead, copy the repository to your local 
  environment, and then copy the repository into the toolbox from there. For 
  example:
```  
`kubectl cp toolboxpod:/opt/workspace/forgeops /tmp/myforgeopscopy; cd /tmp/myforgeopscopy; git push origin master;`
```
