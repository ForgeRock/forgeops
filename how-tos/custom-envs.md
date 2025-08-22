# Using custom ENV vars with ForgeOps

Sometimes you need to configure environment vars on your pods. It could be for
a customization to the platform itself, or a 3rd party tool like app server
monitoring. As of 2025.1.2, the Helm chart gives you this capability.

## How custom ENV vars work in the Helm chart

The Helm chart now allows you to configure `platform.configMap`,
`platform.env`, `am.env`, and `idm.env` populated with a list of env
definitions. The running container in the am and idm deployments and the
platform-config ConfigMap bring these definitions in directly. For example, in
the AM deployment.yaml template we have this:

```
{{- with .Values.platform.env }}
{{- toYaml . | nindent 10 }}
{{- end }}
{{- with .Values.am.env }}
{{- toYaml . | nindent 10 }}
{{- end }}
```

## Defining custom envs

In your `values.yaml` file, you can define one or more of these to configure
extra ENV vars for your deployment.

```
platform:
  configMap:
    enabled: true
    data:
      ENVIRONMENT: "test"
      CUSTOM_SETTING: "value1"
  env:
    - name: MY_GLOBAL_ENV
      value: "MY_GLOBAL_VALUE"
am:
  env:
    - name: MY_ENV
      value: "MY_CUSTOM_VALUE"
idm:
  env:
    - name: MY_ENV
      value: "MY_CUSTOM_VALUE"
```

## Kustomize hints

For Kustomize users, you can add your custom environment variables in the
following places:

* `kustomize/overlay/MY_ENV/base/platform-config.yaml`
* `kustomize/overlay/MY_ENV/am/deployment.yaml`
* `kustomize/overlay/MY_ENV/idm/deployment.yaml`
