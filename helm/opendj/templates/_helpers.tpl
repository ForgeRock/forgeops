{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{define "name"}}{{default "opendj" .Values.nameOverride | trunc 63 }}{{end}}
{{define "fullname"}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{end}}
{{- define "instanceName" -}}
{{- printf "%s" .Values.djInstance -}}
{{end}}
