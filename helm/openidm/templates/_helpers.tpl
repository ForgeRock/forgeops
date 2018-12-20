{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/* expands to the fqdn using the component name. Note domain has a leading . */}}
{{- define "idmFQDN" -}}
{{- if .Values.ingress.hostname  }}{{- printf "%s" .Values.ingress.hostname -}}
{{- else -}}
{{- printf "%s.%s%s" .Values.component .Release.Namespace .Values.domain -}}
{{- end -}}
{{- end -}}


{{/* Inject the TLS spec into the ingress if tls is globally enabled */}}
{{- define "tls-spec" -}}
{{ if or (eq .Values.tlsStrategy "https") (eq .Values.tlsStrategy "https-cert-manager") -}}
tls:
- hosts:
  - {{ template "externalFQDN" .  }}
  secretName: {{ printf "wildcard.%s%s" .Release.Namespace .Values.domain }}
{{- end -}}
{{- end -}}

{{- define "git-init" -}}
{{ if eq .Values.config.strategy "git" }}
- name: git-init
  image: {{ .Values.gitImage.repository }}:{{ .Values.gitImage.tag }}
  imagePullPolicy: {{ .Values.gitImage.pullPolicy }}
  volumeMounts:
  - name: git
    mountPath: /git
  - name: git-secret
    mountPath: /etc/git-secret
  args: ["init"]
  envFrom:
  - configMapRef:
      name:  {{ default "frconfig" .Values.config.name  }}
{{- else -}}
        {}
{{ end }}
{{- end -}}


{{- define "git-sync" -}}
{{ if eq .Values.config.strategy "git" }}
- name: git
  image: {{ .Values.gitImage.repository }}:{{ .Values.gitImage.tag }}
  imagePullPolicy: {{ .Values.gitImage.pullPolicy }}
  volumeMounts:
  - name: git
    mountPath: /git
  - name: git-secret
    mountPath: /etc/git-secret
  env:
  - name: NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
{{ end }}
{{- end -}}