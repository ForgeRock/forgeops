# File Based Configuration (FBC) Notes

This is a work in progress

To run with FBC

```bash
bin/clean.sh
bin/config.sh -v 7.0 init
# Deploy the directory server and secrets first
skaffold -p fbc-ds run
# Wait until ds-idrepo is up.
# Deploy the AM FBC image
skaffold -p fbs run --tail
```

Deploys to https://fbc.iam.forgeops.com/am

Get the amadmin and ldap passwords using `bin/print-secrets.sh 7.0`

ForgeRock note: If you are on the eng-shared cluster, this can be
deployed to the `fbc` namespace, and you will get a real dns and SSL cert.

```bash
gcloud container clusters get-credentials eng-shared --zone us-east1-c --project engineering-devops
kubens fbc # Or kubectl ns fbc - if you use the kubectl plugins
```
# Notes:

* The forgeops-secrets job generates a number of secrets that are injected into 
the pod.  
* The [am-entrypoint.sh](am-entrypoint.sh) script sets more secret values as well as
ldap server names. etc.  There is a env dump that is printed just before AM starts
if you want to see the value
* The am-crypto util is added to the container to encrypt the passwords to be injected
into the config using commons expressions.
* Search for `&{` in `config` to see all the expressions that have been set.
* Edit logback.xml to set the debug level. At TRACE the pod logs quickly get truncated,
so you need to send them off ASAP.  kubectl logs -lapp=am -f >my.log
