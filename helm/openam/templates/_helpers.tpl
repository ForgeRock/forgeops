{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.

We truncate at 24 chars because some Kubernetes name fields are limited to this
(by the DNS naming spec).
*/}}
{{define "fullname"}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 -}}
{{- end -}}


{{/* expands to the fqdn using the component name. Note domain has a leading . */}}
{{- define "externalFQDN2" -}}
{{- printf "login.%s%s"  .Release.Namespace .Values.domain -}}
{{- end -}}



{{/* expands to the fqdn using the component name. Note domain has a leading . */}}
{{- define "externalFQDN" -}}
{{- if .Values.ingress.hostname  }}{{- printf "%s" .Values.ingress.hostname -}}
{{- else -}}
{{- printf "login.%s%s" .Release.Namespace .Values.domain -}}
{{- end -}}
{{- end -}}


{{- define "openam.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "openam.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
