{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{define "name"}}{{default "openam" .Values.nameOverride | trunc 63 }}{{end}}

{{/*
Create a default fully qualified app name.

We truncate at 24 chars because some Kubernetes name fields are limited to this
(by the DNS naming spec).
*/}}
{{define "fullname"}}
{{- $name := default "openam" .Values.nameOverride -}}
{{printf "%s-%s" .Release.Name $name | trunc 63 -}}
{{end}}


{{/* expands to the fqdn using the component name. Note domain has a leading . */}}
{{- define "externalFQDN2" -}}
{{- printf "%s.%s%s" .Values.component .Release.Namespace .Values.global.domain -}}
{{- end -}}


{{- define "openam.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "openam.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
