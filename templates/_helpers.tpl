{{/*
Expand the name of the chart.
*/}}
{{- define "seedkey.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this.
If release name contains chart name it will be used as a full name.
*/}}
{{- define "seedkey.fullname" -}}
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
{{- define "seedkey.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "seedkey.labels" -}}
helm.sh/chart: {{ include "seedkey.chart" . }}
{{ include "seedkey.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "seedkey.selectorLabels" -}}
app.kubernetes.io/name: {{ include "seedkey.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Auth service name
*/}}
{{- define "seedkey.authService.name" -}}
{{- printf "%s-auth-service" (include "seedkey.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Auth service labels
*/}}
{{- define "seedkey.authService.labels" -}}
{{ include "seedkey.labels" . }}
app.kubernetes.io/component: auth-service
{{- end }}

{{/*
Auth service selector labels
*/}}
{{- define "seedkey.authService.selectorLabels" -}}
{{ include "seedkey.selectorLabels" . }}
app.kubernetes.io/component: auth-service
{{- end }}

{{/*
Migrations job name
*/}}
{{- define "seedkey.migrations.name" -}}
{{- printf "%s-migrations" (include "seedkey.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Migrations labels
*/}}
{{- define "seedkey.migrations.labels" -}}
{{ include "seedkey.labels" . }}
app.kubernetes.io/component: migrations
{{- end }}

{{/*
Create the name of the service account to use for auth-service
*/}}
{{- define "seedkey.authService.serviceAccountName" -}}
{{- if .Values.authService.serviceAccount.create }}
{{- default (include "seedkey.authService.name" .) .Values.authService.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.authService.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
ConfigMap name - returns existing ConfigMap name if provided
*/}}
{{- define "seedkey.configMapName" -}}
{{- if .Values.configMap.existingName }}
{{- .Values.configMap.existingName }}
{{- else }}
{{- printf "%s-config" (include "seedkey.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Secret name - returns existing secret name if provided
*/}}
{{- define "seedkey.secretName" -}}
{{- if .Values.secrets.existingSecret }}
{{- .Values.secrets.existingSecret }}
{{- else }}
{{- printf "%s-secrets" (include "seedkey.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Auth service image
*/}}
{{- define "seedkey.authService.image" -}}
{{- $tag := .Values.authService.image.tag | default .Values.authService.version | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.authService.image.repository $tag }}
{{- end }}

{{/*
Migrations image
*/}}
{{- define "seedkey.migrations.image" -}}
{{- $tag := .Values.migrations.image.tag | default .Values.migrations.version | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.migrations.image.repository $tag }}
{{- end }}

{{/*
Namespace to use
*/}}
{{- define "seedkey.namespace" -}}
{{- if .Values.global.namespace }}
{{- .Values.global.namespace }}
{{- else if .Values.namespace.name }}
{{- .Values.namespace.name }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Database host
*/}}
{{- define "seedkey.database.host" -}}
{{- .Values.database.connection.host }}
{{- end }}

{{/*
Image pull secrets
*/}}
{{- define "seedkey.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ .name }}
{{- end }}
{{- end }}
{{- end }}

