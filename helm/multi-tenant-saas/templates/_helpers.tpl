{{/*
Expand the name of the chart.
*/}}
{{- define "multi-tenant-saas.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "multi-tenant-saas.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "multi-tenant-saas.labels" -}}
helm.sh/chart: {{ include "multi-tenant-saas.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
platform: multi-tenant-saas
{{- end }}
