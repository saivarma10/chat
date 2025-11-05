{{/*
Expand the name of the chart.
*/}}
{{- define "chatapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "chatapp.fullname" -}}
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
{{- define "chatapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chatapp.labels" -}}
helm.sh/chart: {{ include "chatapp.chart" . }}
{{ include "chatapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chatapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chatapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chatapp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chatapp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Zookeeper labels
*/}}
{{- define "chatapp.zookeeper.labels" -}}
helm.sh/chart: {{ include "chatapp.chart" . }}
app.kubernetes.io/name: zookeeper
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: zookeeper
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Kafka labels
*/}}
{{- define "chatapp.kafka.labels" -}}
helm.sh/chart: {{ include "chatapp.chart" . }}
app.kubernetes.io/name: kafka
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: kafka
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
