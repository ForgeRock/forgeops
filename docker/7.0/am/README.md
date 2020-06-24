# FBC test


to deploy

```
# switch to fbctest ns
k ns fbctest

# deploy ds and secrets - one time op
skaffold -p fbc-ds run
```

Now to iterate / test fbc:

```
skaffold -p am-fbc dev
```


```
# To get logs:
k logs -lapp=am | tee  out.log

# env vars
k exec deploy/am -it -- env

# copy the contents of openam for inspection
k cp am-xxx:/home/forgerock/openam  tmp-openam/

```

Current State:
- Errors on startup. LDAP error - maybe the CTS?
- Debug logs are super hard to read. Maybe we put them back to plain text while we debug?
