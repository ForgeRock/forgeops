{{/*
# See https://github.com/kubernetes/git-sync/issues/38
#      securityContext:
#        runAsUser: 0
#      initContainers:
#   include "git-sync" . | indent 6
*/}}
{{- define "git-sync" -}}
- name: git-sync
  image: "gcr.io/google_containers/git-sync:v2.0.4"
  imagePullPolicy: IfNotPresent
  volumeMounts:
  - name: git
    mountPath: /git
 {{- if hasPrefix "ssh:" .Values.git.repo }}
  - name: git-secret
    mountPath: /etc/git-secret
 {{- end }}
  env:
  - name: GIT_SYNC_REPO
    value: {{ .Values.git.repo }}
  - name: GIT_SYNC_DEST
    value: forgeops-init
  - name: GIT_SYNC_ONE_TIME
    value: "true"
  - name: GIT_SYNC_BRANCH
    value: {{ .Values.git.branch }}
  {{- if hasPrefix "ssh:" .Values.git.repo }}
  - name: GIT_SYNC_SSH
    value: "true"
  {{- end }}
{{- end -}}


{{/* expands to the fqdn using the component name. Note domain has a leading . */}}
{{- define "externalFQDN" -}}
{{- if .Values.ingress.hostname  }}{{- printf "%s" .Values.ingress.hostname -}}
{{- else -}}
{{- printf "%s.%s%s" .Values.component .Release.Namespace .Values.global.domain -}}
{{- end -}}
{{- end -}}


{{/* Inject the TLS spec into the ingress if tls is globally enabled */}}
{{- define "tls-spec" -}}
{{ if .Values.global.useTLS -}}
tls:
- hosts:
  - {{ template "externalFQDN" .  }}
  secretName: {{ template "externalFQDN" . }}
{{ end -}}
{{- end -}}