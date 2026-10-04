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
Common labels (no versioning labels)
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
Create a common image helper that can setup a good image string
*/}}
{{- define "common.image" }}
{{- $repository := .image.repository | toString }}
{{- $tag := (.image.tag | default .default_tag) | toString }}
{{- if hasPrefix "sha256:" $tag }}
{{- printf "%s@%s" $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
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
Create a ClusterRole name for creating an ssh key
*/}}
{{- define "ssh_keygen.clusterRoleName" }}
{{- if .Values.ssh_keygen.appendNSToRole }}
{{- printf "%s:%s" .Values.ssh_keygen.clusterRoleName .Release.Namespace }}
{{- else }}
{{- .Values.ssh_keygen.clusterRoleName }}
{{- end }}
{{- end }}

{{/*
Define the key in the amster secret for the private SSH key
*/}}
{{- define "amster.ssh.private_key_name" }}
{{- if and .Values.platform.secrets_enabled .Values.platform.secrets.amster (hasKey .Values.platform.secrets.amster "annotations") (hasKey .Values.platform.secrets.amster.annotations "secret-generator.v1.mittwald.de/type") }}
{{- printf "ssh-privatekey" }}
{{- else }}
{{- printf "id_rsa" }}
{{- end }}
{{- end }}

{{/*
Define the key in the amster secret for the public SSH key
*/}}
{{- define "amster.ssh.public_key_name" }}
{{- if and .Values.platform.secrets_enabled .Values.platform.secrets.amster (hasKey .Values.platform.secrets.amster.annotations "secret-generator.v1.mittwald.de/type") }}
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
{{- if and .Values.keystore_create.enabled (or .Values.keystore_create.force (and .Values.platform.secrets_enabled .Values.platform.secrets.keystore_create (or .Values.am.enabled .Values.idm.enabled))) }}
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
{{- if and .Values.keystore_create.enabled .Values.platform.secrets_enabled (or .Values.platform.base_generate .Values.platform.secrets.keystore_create) (or .Values.am.enabled .Values.idm.enabled) }}
{{- printf "true" }}
{{- else }}
{{- printf "false" }}
{{- end }}
{{- end }}

{{/*
Define a variable that determines if we should enable the ssh_keygen job.
*/}}
{{- define "ssh_keygen.enabled" }}
{{- if and .Values.ssh_keygen.enabled (or .Values.am.enabled .Values.amster.enabled) }}
{{- printf "true" }}
{{- else }}
{{- printf "false" }}
{{- end }}
{{- end }}

{{/*
Directory under the chart that holds the runtime scripts packaged into the
product ConfigMaps (DS and IDM). The Alpine-based product images
(IMAGE_MODE=forgeops) run with busybox ash and need the POSIX variants in
files-alpine; everything else keeps the original files/ scripts.
*/}}
{{/*
The uid the product pods run as. The Debian product images expect the
historic 11111 (forgerock) uid - the podSecurityContext default, passed as the
single argument. The alpine pingbase-built images (platform.imageMode=forgeops)
bake their file ownership for the pingbase uid (ping, 9031), so forgeops mode
replaces the default 11111 with 9031; any runAsUser a deployer sets explicitly
(anything other than the 11111 default) is left untouched in every mode.
*/}}
{{- define "platform.runAsUser" -}}
{{- $current := int (index . 0) -}}
{{- $root := index . 1 -}}
{{- if and (eq ($root.Values.platform.imageMode | default "base") "forgeops") (eq $current 11111) -}}
{{- printf "9031" -}}
{{- else -}}
{{- printf "%d" $current -}}
{{- end -}}
{{- end -}}

{{/* Home directory of the product images: the Debian images run the
     forgerock user (/home/forgerock); the alpine pingbase images run ping
     (/home/ping = $PING_HOME = $FORGEROCK_HOME baked into the alpine
     images). Branches every path that overlays the image's home. */}}
{{- define "platform.amHome" -}}
{{- if eq (.Values.platform.imageMode | default "base") "forgeops" -}}
{{- printf "/home/ping" -}}
{{- else -}}
{{- printf "/home/forgerock" -}}
{{- end -}}
{{- end -}}

{{/* Tomcat install directory: the Debian images put it at
     /usr/local/tomcat; the alpine pingbase-tomcat images use
     /opt/tomcat (CATALINA_HOME). */}}
{{- define "platform.amCatalina" -}}
{{- if eq (.Values.platform.imageMode | default "base") "forgeops" -}}
{{- printf "/opt/tomcat" -}}
{{- else -}}
{{- printf "/usr/local/tomcat" -}}
{{- end -}}
{{- end -}}

{{- define "platform.filesDir" -}}
{{- if eq (.Values.platform.imageMode | default "base") "forgeops" -}}
{{- printf "files-alpine" -}}
{{- else -}}
{{- printf "files" -}}
{{- end -}}
{{- end -}}

{{/*
The full "<repository>/<name>:<tag>" image ref a product component runs.
The repository resolves per component as:
  1. component .image.repository (an explicit deployer pin) - always wins
  2. platform.imageRepository (the chart-wide default, e.g.
     us-docker.pkg.dev/forgeops-public/images)
and the name (the image's basename inside that repository) as:
  1. component .image.name (an explicit deployer override) - when set
  2. the platform default name (arg 2: ds, am, idm, amster, admin-ui,
     end-user-ui, login-ui, idm-admin-ui)
Both platform values compose: platform.imageRepository + "/" + name. The
tag resolves as component .image.tag | default AppVersion (arg 3), exactly
as the templates resolved it before this helper existed. Example:
  include "platform.imageRef" (list . .Values.ds_idrepo.image "ds" .Chart.AppVersion)
*/}}
{{- define "platform.imageRef" -}}
{{- $root := index . 0 -}}
{{- $args := index . 1 -}}
{{- $image := index $args 0 -}}
{{- $defaultName := index $args 1 -}}
{{- $tag := index $args 2 -}}
{{- if and (index $image "repository") (ne (toString (index $image "repository")) "") -}}
{{- printf "%s:%s" (toString (index $image "repository")) (index $image "tag" | default $tag) -}}
{{- else -}}
{{- $name := default $defaultName (index $image "name") -}}
{{- printf "%s/%s:%s" (toString $root.Values.platform.imageRepository) $name (index $image "tag" | default $tag) -}}
{{- end -}}
{{- end -}}
