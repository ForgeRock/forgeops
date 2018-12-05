{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/* expands to the fqdn using the component name. Note domain has a leading . */}}
{{- define "igFQDN" -}}
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