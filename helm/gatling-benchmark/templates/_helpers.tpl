{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* expands to the fqdn using the component name. Note domain has a leading . */}}
{{- define "externalFQDN" -}}
{{- if .Values.ingress.hostname  }}{{- printf "%s" .Values.ingress.hostname -}}
{{- else -}}
{{- printf "%s.%s.%s" .Release.Namespace .Values.subdomain .Values.domain -}}
{{- end -}}
{{- end -}}
