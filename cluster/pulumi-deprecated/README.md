# ForgeRock Cloud Infrastructure Setup using Pulumi

The Pulumi scripts in this folder enables a user to setup and manage the cloud infrastructure
required to successfully deploy ForgeRock CDM samples.
<br />

## Prerequisites
* Kubernetes client version 1.14+
* Pulumi version 0.17.25+
<br />

## Pulumi setup steps
The samples in this folder are based on Pulumi's default language of Typescript with Node.js.
Other languages are available but not documented here.

* Configure your cloud CLI if necessary: https://www.pulumi.com/docs/quickstart/.

* Download and install Pulumi: https://pulumi.io/reference/install/.

* Download and install Node.js: https://nodejs.org/en/download/.

On a mac you can install Pulumi and its dependencies using:

```
brew install pulumi
```

Login using a shared gcs backend. For example, if you have a bucket named `forgerock-pulumi`:

```
pulumi login gs://forgerock-pulumi/<namespace>
```

Include a namespace to work under. This is where all your stacks and state files will be stored. Either use name/username for a personal namespace , or deployment sample name(e.g. cdm) for shared namespace.

The shared namespace is designed to enable users to have a shared view of the resources that are created. Allowing one user to create a resource and another to update or delete it.

Alternatively run Pulumi in local mode(good for testing but no good for sharing):
(Prevents requiring to login to the Pulumi service online but don't run this command if you would like to use it)
```
pulumi login -l
```

#### Backend folders
Under \<namespace\>/.pulumi:
```
stacks/ - includes latest deployed stack file and a backup copy.
history/*.checkpoint - transactional snapshots files(state).
history/*.history - snapshot of the pulumi action taken and the configuration values that correspond with the above checkpoint.
backup/ - full historical state backups.
```

Note: If you're using the gcs backend, you will occasionally see (warnings)[https://github.com/pulumi/pulumi/issues/2791] using the gcs backend, but it does work.
<br />

## Pulumi project setup steps

#### Key project files
```
Pulumi.yaml - defines the project.
Pulumi.<stackname>.yaml - contains configuration values for the stack we initialized.
index.ts - the Pulumi program that defines our stack resources. Let’s examine it.
```

#### Setup steps
These steps need to be carried out inside the cloud providers directory in the pulumi folder.  The same actions need to be repeated for each cloud provider that you are using.

```IMPORTANT``` Create your own branch so you can configure your own Pulumi stacks. If you wish to access a stack that has already been deployed, you will need to be on the same  branch that deployed the resources originally and login to the same shared backend.


1. Install dependencies
(this generates node_modules directory. This is ignored by git as is too large to commit):
    ```
    cd /path/to/forgeops/cluster/pulumi/
    npm install
    ```

2. CD to the cloud provider folder that you want to use:
    ```
    cd [eks OR gke OR aks]
    ```

3. Running Pulumi in local mode or logging into a GCP bucket requires a passphrase to protect your stack.  You can set the following ENV variable to save you retyping passphrase every time. Default = "password" :
    ```
    export PULUMI_CONFIG_PASSPHRASE=password
    ```

4. Set up your Pulumi stacks.  The stack name needs to match the second part of the *Pulumi.\<stack\>.yaml* files.
If you are storing state in a bucket or using local login, stacks need to have unique names across projects(Pulumi are looking into this https://github.com/pulumi/pulumi/issues/2522).
Please use format, <projectname>-<deployment name> so in GKE project please use:
    ```
    cd /path/to/forgeops/cluster/pulumi/gcp/infra
    pulumi stack init gcp-infra
    cd /path/to/forgeops/cluster/pulumi/gcp/gke
    pulumi stack init gke-small
    ```

    ```NOTE``` If you change your passphrase or stack/project cofiguration, please don't commit back to forgeops unless it's an improvement.

5. GCP ONLY.  Please configure Pulumi to use your GCP project id. This can either be done per stack by running the following command:
    ```
    pulumi config set gcp:project my-project-id -s <stack name>
    ```
    or set environment variable(only available in current shell session):
    ```
    export GOOGLE_PROJECT=<gcp project>
    ```
<br />

## Configure and run your deployment

#### Configuring your stack
The environment and configurations of your stack are defined in the *Pulumi.\<stackname\>.yaml* file. Values can be added directly to the *Pulumi.\<stackname\>.yaml* file or using the command line:

```
pulumi config set <var> <value>
```
```NOTE```: Do not edit *./config.ts*.

Your stack file can contain encrypted variables using a unique stack key(encryption salt) string at the top of your stack file.  These values are decrypted by Pulumi at runtime.

To add an encrypted secret:
```
pulumi config set --secret <secretVar> <secret>
```
```NOTE```: Using cmdline reformats the stackfile into alphabetical order.


#### Deploy your stack
Once you have configured your stacks, change your directory to the location of the stack, select stack and deploy (or add the -s <stack> flag each time to the up command):
```
cd /path/to/forgeops/cluster/pulumi/gke/infra
pulumi stack select gcp-infra
pulumi up
```
NOTE: You need to do this for every stack. i.e.: deploy the gcp-infra stack first and then gke-small

Grab kubeconfig output from stack and set context:
```
pulumi stack output kubeconfig > kubeconfig
export KUBECONFIG=$PWD/kubeconfig
```
or run:
```
. ../bin/set-kubeconfig.sh
```

Verify:
```
kubectx
kubens # check for cert-manager and nginx namespaces and that the services are running.
```

Remove the selected stack:
```
pulumi destroy
```

```NOTE``` Sometimes, you may find that one of the Helm chart components doesn't succeed.  This is often to do with the ordering of deployed resources within a Helm chart. If this happens, running Pulumi up a 2nd time usually resolves this.
<br />

## Switching cloud projects

To run a particular cloud stack you need to ensure you are inside the correct cloud folder inside the Pulumi folder.
As the kubeconfig file is set local to a project, remember to reset when switching:
```
export KUBECONFIG=$PWD/kubeconfig
```
or:
```
. ../bin/set-kubeconfig.sh
```
<br />

## Useful commands

Preview stack:
```
pulumi preview
```

View/edit state file:
```
pulumi stack export --file output
# edit file, i.e. you can remove resources if they get removed outside of Pulumi, or remove pending operations if Pulumi gets interrupted
pulumi stack import --file output
```

View config values used in stack:
```
pulumi config
```

View decrypted secret values:
```
pulumi config --show-secrets
```

View stack logs:
```
pulumi stack logs
```

Delete stack without removing the Pulumi.\<stack\>.yaml. This clears all the stack files from the backend:
```
pulumi stack rm <stack> --preserve-config
```

To add additional labels to a Node Pool, set an object e.g. to add 2 extra labels to the primary Node Pool:

```
pulumi config set primary:labels '{"myKey1": "myValue1", "myKey2": "myValue2"}'
```

To add additional taints to a Node Pool, set an array of objects e.g. to add 2 extra taints to the primary Node Pool:

```
pulumi config set primary:taints '[{"key": "myKey", "value": "myValue", "effect": "NO_SCHEDULE"},{"key": "myKey2", "value": "myValue2", "effect": "NO_SCHEDULE"}]'
```







