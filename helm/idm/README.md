# Sample Helm chart to deploy OpenIDM

This chart depends on the postgresql chart for the OpenIDM repository database. The
postgresql chart has been kept separate so that OpenIDM can be started / stopped
independent of the database.

## Design

The chart assumes that the OpenIDM configuration files (/conf/*.json, scripts/* , etc.) are 
mounted on the OpenIDM container as a volume at runtime.


## Configuration settings

See [frconfig] (../frconfig/README.md) for instructions on how to install a configuration repository.

The IDM configuration is cloned from git and made available to IDM at startup.

The `config.path` variable in values.yaml
should point to the absolute path of the idm project.  The git repo is checked out under a top level path
of /git/config.  So if for example, your git repository contains an idm project at `test/my-great-project` you will
set `config.path: /git/config/test/my-great-project`.  

Please see [values.yaml](values.yaml) for additional settings.

## Development Example

Create a custom.yaml file that overrides any required values found in the chart openidm/values.yaml. Please 
see the comments in values.yaml to understand what you can override.

Deploy PostgreSQL and OpenIDM to Minikube:

```shell
helm install --name postgresql postgresql
sleep 30 
helm install --name openidm -f custom-openidm.yaml openidm 

```

You can access OpenIDM at the ingress defined path: https://openidm.default.example.com
