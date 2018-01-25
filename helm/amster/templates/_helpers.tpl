{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 24 characters because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/* OpenAM FQDN  - if it is not explicity set, generate it */}}
{{- define "openamFQDN" -}}
{{- if .Values.openamFQDN  }}{{- printf "%s" .Values.openamFQDN -}}
{{- else -}}
{{- printf "openam.%s%s" .Release.Namespace .Values.global.domain -}}
{{- end -}}
{{- end -}}
