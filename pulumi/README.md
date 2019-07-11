# ForgeRock Cloud Infrastructure Setup using Pulumi

The Pulumi scripts in this folder allows a user to setup and manage the cloud infrastructure
required to successfully deploy ForgeRock CDM samples.

## Pulumi setup steps
The samples in this folder are based on Pulumi's default language of Typescrypt with Node.js.
Other languages are available but not documented here.

* Configure your cloud CLI if necessary: https://www.pulumi.com/docs/quickstart/.

* Download and install Pulumi: https://pulumi.io/reference/install/.

* Download and install Node.js: https://nodejs.org/en/download/.

On a mac you can install Pulumi and its dependencies using:

```
brew install pulumi
```

Login using a shared gcs backend:

```
pulumi login gs://forgeops-pulumi/<namespace>
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

Note: You will occasionally see (warnings)[https://github.com/pulumi/pulumi/issues/2791] using the gcs backend, but it does work.

## Pulumi project setup steps

#### Key project files
```
Pulumi.yaml - defines the project.
Pulumi.<stackname>.yaml - contains configuration values for the stack we initialized.
index.ts - the Pulumi program that defines our stack resources. Let’s examine it.
```

#### Actions
These actions need to be carried out inside the cloud providers directory in the pulumi folder.  The same actions need to be repeated for each cloud provider that you are using.

```IMPORTANT``` Create your own branch so you can configure your own Pulumi stacks. If you are accessing a shared stack, you will need to be on the same  branch that deployed the resources originally and login to the shared backend.

CD into the cloud provider folder that you want to use
```
cd <aws/azure/gcp>
```

Install dependencies:
(this generates node_modules directory. This is ignored by git as is too large to commit)
```
npm install
```

Running Pulumi in local mode or logging into a GCP bucket requires a passphrase to protect your stack.  You can set the following ENV variable to save you retyping passphrase every time. Default = "password" :
```
export PULUMI_CONFIG_PASSPHRASE=password
```

Setup your Pulumi stacks.  The stack name needs to match the second part of the *Pulumi.\<stack\>.yaml* files.
If you are storing state in a bucket or using local login, stacks need to have unique names across projects(Pulumi are looking into this https://github.com/pulumi/pulumi/issues/2522).
Please use format, <projectname>-<deployment name> so in GKE project please use:
```
pulumi stack init gke-small
pulumi stack init gke-medium
pulumi stack init gke-large
```

```NOTE``` If you change your passphrase or stack/project cofiguration, please don't commit back to forgeops unless it's an improvement.

Set kubeconfig
```
export KUBECONFIG=$PWD/kubeconfig
```

## Configure and run your deployment

#### Configuring your stack
All configuration values are defined and initialized in *./config.ts*. These values inherit from your *Pulumi.\<stackname\>.yaml*.  
The environment you wish to deploy to is defined within the *Pulumi.\<stackname\>.yaml*. To configure your stack, you must set your values in your *Pulumi.\<stackname\>.yaml*. Do not edit *./config.ts*.

The *Pulumi.\<stackname\>.yaml* contains 2 types of variables:
* \<cloud-provider\>:\<varname\> which allow you to define specific cloud wide variables like region and project name.  These can be used in any .ts file.
* \<stack-name\>:\<varname\> which are custom stack variables which are referenced in *./config.ts*

Also your stack file can contain encrypted variables using a unique stack key(encryption salt) string at the top of your stack file.  These values are decrypted by Pulumi at runtime.

Values can be added directly to *Pulumi.\<stackname\>.yaml* file or  
Add configuration values using cmdline:
```
pulumi config set <var> <value>
```

Add an encrypted secret:
```
pulumi config set --secret <secretVar> <secret>
```


#### Deploy your stack
Once you have configure you're stack, select stack and deploy(or add the -s <stack> flag each time to the up command):
```
pulumi stack select <stack>
pulumi up
```

Grab kubeconfig output from stack and set context. 
```
pulumi stack output kubeconfig > kubeconfig
export KUBECONFIG=$PWD/kubeconfig
```
or run 
```
. ../bin/set-kubeconfig.sh
```

Verify
```
kubectx
kubens # check for cert-manager and nginx namespaces and that the services are running.
```

Remove the selected stack:
```
pulumi destroy
```

## Switching projects

As the kubeconfig file is set local to a project, remember to reset when switching:
```
export KUBECONFIG=$PWD/kubeconfig
```
or 
```
. ../bin/set-kubeconfig.sh
```

## Useful commands

Preview stack
```
pulumi preview
```

View/edit state file.
```
pulumi stack export --file output
# edit file, i.e. you can remove resources if they get removed outside of Pulumi, or remove pending operations if Pulumi gets interrupted
pulumi stack import --file output
```

View decryted secret values
```
pulumi stack --show-secrets
```

View stack logs
```
pulumi stack logs
```

Delete stack without removing the Pulumi.\<stack\>.yaml. This clears all the stack files from the backend.
```
pulumi stack rm <stack> --preserve-config
```







