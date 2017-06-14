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