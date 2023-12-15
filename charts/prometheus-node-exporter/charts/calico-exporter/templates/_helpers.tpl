{{/*
Expand the name of the chart.
*/}}
{{- define "calico-exporter.name" -}}
{{- if hasKey .Values "CalicoExporter" -}}
{{- default .Chart.Name .Values.CalicoExporter.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "calico-exporter.fullname" -}}
{{- if hasKey .Values "CalicoExporter" -}}
{{- if .Values.CalicoExporter.fullnameOverride }}
{{- .Values.CalicoExporter.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.CalicoExporter.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- else }}
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
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "calico-exporter.serviceAccountName" -}}
   {{ default "default" .Values.serviceAccount.name }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "calico-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "calico-exporter.labels" }}
helm.sh/chart: {{ include "calico-exporter.chart" . }}
{{- include "calico-exporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ printf "%s%s" "v" .Chart.AppVersion | quote}}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "calico-exporter.bgp-collector.labels" }}
{{- include "calico-exporter.labels" . }}
app.kubernetes.io/component: bgp-collector
{{- end }}

{{- define "calico-exporter.ippool-collector.labels" }}
{{- include "calico-exporter.labels" . }}
app.kubernetes.io/component: ippool-collector
{{- end }}

{{- define "calico-exporter.kube-controllers.labels" }}
{{- include "calico-exporter.labels" . }}
app.kubernetes.io/component: calico-kube-controllers
k8s-app: calico-kube-controllers
{{- end }}

{{/*
Selector labels
*/}}
{{- define "calico-exporter.selectorLabels" }}
app.kubernetes.io/name: {{ include "calico-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "calico-exporter.bgp-collector.selectorLabels" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Values.podLabels }}
{{ toYaml .Values.podLabels }}
{{- end }}
{{- end }}

{{- define "calico-exporter.ippool-collector.selectorLabels" }}
{{- include "calico-exporter.selectorLabels" . }}
app.kubernetes.io/component: ippool-collector
{{- end }}

{{- define "calico-exporter.kube-controllers.selectorLabels" }}
k8s-app: calico-kube-controllers
{{- end }}
