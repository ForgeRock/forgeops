>NOTE: This README is for the new forgeops-ng command only which is currently in technology preview status

This directory contains per environment (env) values files to be used with our Helm
chart. These files are created and managed by the `forgeops-ng env` command. It
will create several files per env.

| File | Description |
|------|-------------|
| env.log | Log tracking calls to `forgeops-ng env` |
| values.yaml | All settings |
| values-images.yaml | App image settings |
| values-ingress.yaml | Ingress configuration |
| values-size.yaml | Replica, cpu, and memory settings |

In general, we recommend using the `values.yaml` file, but we provide the
others for folks that want/need to manage their install with multiple files.
You can edit these files and add settings to them, and the `forgeops-ng env`
command will not overwrite them. It will only overwrite a setting it manages if
you tell it to.

So if you wanted to create a stage env with the small size, you could do this:
```
cd /path/to/forgeops
./bin/forgeops-ng env --small --fqdn stage.example.com --env-name stage
git add helm/stage
git commit -am 'Adding stage env'
git push
helm install identity-platform -f helm/stage/values.yaml ./charts/identity-platform
```

By default, the env command outputs values files and a Kustomize overlay. If
you don't want it to output a Kustomize overlay, set `NO_KUSTOMIZE=true` in
`/path/to/forgeops/forgeops-ng.conf`.
