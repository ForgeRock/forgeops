{{/*
Expand the name of the chart.
*/}}
{{- define "identity-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "identity-platform.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "identity-platform.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "identity-platform.labels" -}}
helm.sh/chart: {{ include "identity-platform.chart" . }}
{{ include "identity-platform.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels (no versioning lables)
*/}}
{{- define "identity-platform.labelsUnversioned" -}}
{{ include "identity-platform.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "identity-platform.selectorLabels" -}}
app.kubernetes.io/name: {{ include "identity-platform.name" . }}
app.kubernetes.io/part-of: {{ include "identity-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "identity-platform.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "identity-platform.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the snapshot script configmap use
*/}}
{{- define "ds-snapshot.configMapName" }}
{{- printf "%s-script" .Values.ds_snapshot.serviceAccountName }}
{{- end }}

{{/*
Create a ClusterRole name for volume snapshots
*/}}
{{- define "ds-snapshot.clusterRoleName" }}
{{- if .Values.ds_snapshot.appendNSToRole }}
{{- printf "%s-%s" .Values.ds_snapshot.clusterRoleName .Release.Namespace }}
{{- else }}
{{- .Values.ds_snapshot.clusterRoleName }}
{{- end }}
{{- end }}

{{/*
Create a ClusterRole name for creating a keystore
*/}}
{{- define "keystore-create.clusterRoleName" }}
{{- if .Values.keystore_create.appendNSToRole }}
{{- printf "%s:%s" .Values.keystore_create.clusterRoleName .Release.Namespace }}
{{- else }}
{{- .Values.keystore_create.clusterRoleName }}
{{- end }}
{{- end }}

{{/*
Define the key in the amster secret for the private SSH key
*/}}
{{- define "amster.ssh.private_key_name" }}
{{- if and .Values.platform.secret_generator_enable (or .Values.platform.secrets.amster .Values.platform.base_generate) }}
{{- printf "ssh-privatekey" }}
{{- else }}
{{- printf "id_rsa" }}
{{- end }}
{{- end }}

{{/*
Define the key in the amster secret for the public SSH key
*/}}
{{- define "amster.ssh.public_key_name" }}
{{- if and .Values.platform.secret_generator_enable (or .Values.platform.secrets.amster .Values.platform.base_generate) }}
{{- printf "ssh-publickey" }}
{{- else }}
{{- printf "id_rsa.pub" }}
{{- end }}
{{- end }}

{{/*
Define a variable that determines if we should enable the keystore_create job.
The Values.keystore_create.force allows base-generate.sh to create just the relevant resources.
*/}}
{{- define "keystore_create.enabled" }}
{{- if and .Values.keystore_create.enabled (or .Values.keystore_create.force (and .Values.platform.secret_generator_enable .Values.platform.secrets.keystore_create (or .Values.am.enabled .Values.idm.enabled))) }}
{{- printf "true" }}
{{- else }}
{{- printf "false" }}
{{- end }}
{{- end }}

{{/*
Define a variable that determines if we should enable the keystore_create resources in deployments like am and idm.
The Values.platform.base_generate allows base-generate.sh to create just the relevant resources.
*/}}
{{- define "keystore_create.resources.enabled" }}
{{- if and .Values.keystore_create.enabled .Values.platform.secret_generator_enable (or .Values.platform.base_generate .Values.platform.secrets.keystore_create) (or .Values.am.enabled .Values.idm.enabled) }}
{{- printf "true" }}
{{- else }}
{{- printf "false" }}
{{- end }}
{{- end }}
