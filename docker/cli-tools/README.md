# ForgeOps CLI

ForgeOps cli is a container that contains all tools used/needed to provision GKE/EKS/AKS.



Basic Example:
```
GIT_ROOT=root of forgeops repo
cd cluster/pulumi/gcp/infra
export PULUMI_CONFIG_PASSPHRASE=changeme
$GIT_ROOT/bin/cli.sh pulumi stack select
$GIT_ROOT/bin/cli.sh pulumi up --yes
    ...pulumi output...
cd ../../gke
$GIT_ROOT/bin/cli.sh pulumi stack select
$GIT_ROOT/bin/cli.sh pulumi up --yes
```


`bin/cli.sh` is a wrapper that calls docker run and provides all arguments for the docker run command. `cli.sh` mounts the necessary directories from the host machine to ensure the container is stateless. This means the Pulumi home directory is kept on the host machine. For Pulumi to create and interact with the cloud providers API it needs credentials which are in the host machines user's home directory. These credentials are mounted as well during runtime of the container. The cli container takes careful steps to avoid userid side effects on the host machine.  The container runs as the same uid as the host system to maintain proper file system permissions.


**Note:** `export PULUMI_CONFIG_PASSPHRASE=my cool password` must be set before running the cli.sh.

## Running Pulumi in the container

`bin/cli.sh` uses the container `gcr.io/engineering-devops/forgeops-cli` which has packaged within the container all code in `cluster/pulumi` at the time of the build. When the Pulumi command is issued it uses the Pulumi typescript in the container but the stack file from the current working director of where the script is being executed. The user of the script should not change typescript and then expect the container to run those changes (at this moment). The stack file must exist in the current working directory and the user must be in `cluster/pulumi/{aws,azure,gcp}/{eks,infra}` in order for Pulumi to work.


## Warnings

* The image is around 1.8gb due to support for all three cloud providers
* `aws help` does not work
* `bin/cli.sh` wont work on windows
* azure is NOT tested because its under re-work at the moment
* `bin/cli.sh` doesn't provide any locally set environment vars to the container
*  needs a `run from source` option that will run the container from source code on host machine
* `bin/cli.sh` is a bit slower, because every run the container has to change the UID of the user to match the host machine user

