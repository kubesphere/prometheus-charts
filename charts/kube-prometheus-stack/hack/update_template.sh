#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# update_templates 替换 {{ template "kube-prometheus-stack.name" . }}-<template> 为 {{ template "kube-prometheus-stack.<template>.heritageName" . }}, 为了使用先前保留的名称
update_templates(){
    echo "Replace prometheus-operator deployment name"
    if [[ $(uname -s) = "Darwin" ]]; then
        sed -i '' "7s/{{ template \"kube-prometheus-stack.fullname\" . }}-operator/{{ template \"kube-prometheus-stack.prometheus-operator.heritageName\" . }}/" ${SCRIPT_DIR}/../templates/prometheus-operator/deployment.yaml
        # find ${SCRIPT_DIR}/../templates/  -type f -name "*.yaml" -exec sed -i '' "s/{{ template \"kube-prometheus-stack.fullname\" . }}-${template}/{{ template \"kube-prometheus-stack.${template}.heritageName\" . }}/g" {} +
    else
        sed -i "7s/{{ template \"kube-prometheus-stack.fullname\" . }}-operator/{{ template \"kube-prometheus-stack.prometheus-operator.heritageName\" . }}/" ${SCRIPT_DIR}/../templates/prometheus-operator/deployment.yaml

    fi
}

add_heritage_service(){
    echo "add prometheus-operator heritage service"

    prometheusOperatorHeritageServiceContext=$(cat <<EOF
{{- if and .Values.prometheusOperator.enabled .Values.prometheusOperator.heritageName }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.prometheusOperator.heritageName }}
  namespace: {{ template "kube-prometheus-stack.namespace" . }}
  labels:
    app: {{ .Values.prometheusOperator.heritageName }}
{{ include "kube-prometheus-stack.labels" . | indent 4 }}
{{- if .Values.prometheusOperator.service.labels }}
{{ toYaml .Values.prometheusOperator.service.labels | indent 4 }}
{{- end }}
{{- if .Values.prometheusOperator.service.annotations }}
  annotations:
{{ toYaml .Values.prometheusOperator.service.annotations | indent 4 }}
{{- end }}
spec:
  ports:
  {{- if not .Values.prometheusOperator.tls.enabled }}
  - name: http
    {{- if eq .Values.prometheusOperator.service.type "NodePort" }}
    nodePort: {{ .Values.prometheusOperator.service.nodePort }}
    {{- end }}
    port: 8080
    targetPort: http
  {{- end }}
  {{- if .Values.prometheusOperator.tls.enabled }}
  - name: https
    {{- if eq .Values.prometheusOperator.service.type "NodePort"}}
    nodePort: {{ .Values.prometheusOperator.service.nodePortTls }}
    {{- end }}
    port: 443
    targetPort: https
  {{- end }}
  selector:
    app: {{ template "kube-prometheus-stack.name" . }}-operator
    release: {{ $.Release.Name | quote }}
  type: ClusterIP
{{- end }}

EOF
)
    echo "${prometheusOperatorHeritageServiceContext}" > ${SCRIPT_DIR}/../templates/prometheus-operator/heritage-service.yaml

    echo "add prometheus heritage service"
    prometheusHeritageServiceContext=$(cat <<EOF
{{- if and .Values.prometheus.enabled .Values.prometheus.heritageName}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.prometheus.heritageName }}
  namespace: {{ template "kube-prometheus-stack.namespace" . }}
  labels:
    app: {{ template "kube-prometheus-stack.name" . }}-prometheus
{{ include "kube-prometheus-stack.labels" . | indent 4 }}
{{- if .Values.prometheus.service.labels }}
{{ toYaml .Values.prometheus.service.labels | indent 4 }}
{{- end }}
{{- if .Values.prometheus.service.annotations }}
  annotations:
{{ toYaml .Values.prometheus.service.annotations | indent 4 }}
{{- end }}
spec:
  ports:
  - name: {{ .Values.prometheus.prometheusSpec.portName }}
    port: {{ .Values.prometheus.service.port }}
    targetPort: {{ .Values.prometheus.service.targetPort }}
  - name: reloader-web
    port: 8080
    targetPort: reloader-web
  {{- if .Values.prometheus.thanosIngress.enabled }}
  - name: grpc
    port: {{ .Values.prometheus.thanosIngress.servicePort }}
    targetPort: {{ .Values.prometheus.thanosIngress.servicePort }}
  {{- end }}
  selector:
    {{- if .Values.prometheus.agentMode }}
    app.kubernetes.io/name: prometheus-agent
    {{- else }}
    app.kubernetes.io/name: prometheus
    {{- end }}
    operator.prometheus.io/name: {{ template "kube-prometheus-stack.prometheus.crname" . }}
{{- if .Values.prometheus.service.sessionAffinity }}
  sessionAffinity: {{ .Values.prometheus.service.sessionAffinity }}
{{- end }}
  type: ClusterIP
{{- end }}
EOF
)
    echo "${prometheusHeritageServiceContext}" > ${SCRIPT_DIR}/../templates/prometheus/heritage-service.yaml

    echo "add alertmanager heritage service"
    alertmanagerHeritageServiceContext=$(cat <<EOF
{{- if and .Values.alertmanager.enabled .Values.alertmanager.heritageName}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.alertmanager.heritageName }}
  namespace: {{ template "kube-prometheus-stack.namespace" . }}
  labels:
    app: {{ template "kube-prometheus-stack.name" . }}-alertmanager
{{ include "kube-prometheus-stack.labels" . | indent 4 }}
{{- if .Values.alertmanager.service.labels }}
{{ toYaml .Values.alertmanager.service.labels | indent 4 }}
{{- end }}
{{- if .Values.alertmanager.service.annotations }}
  annotations:
{{ toYaml .Values.alertmanager.service.annotations | indent 4 }}
{{- end }}
spec:
  ports:
  - name: {{ .Values.alertmanager.alertmanagerSpec.portName }}
    port: {{ .Values.alertmanager.service.port }}
    targetPort: {{ .Values.alertmanager.service.targetPort }}
    protocol: TCP
  - name: reloader-web
    port: 8080
    targetPort: reloader-web
  selector:
    app.kubernetes.io/name: alertmanager
    alertmanager: {{ template "kube-prometheus-stack.alertmanager.crname" . }}
{{- if .Values.alertmanager.service.sessionAffinity }}
  sessionAffinity: {{ .Values.alertmanager.service.sessionAffinity }}
{{- end }}
  type: ClusterIP
{{- end }}
EOF
)
    echo "${alertmanagerHeritageServiceContext}" > ${SCRIPT_DIR}/../templates/alertmanager/heritage-service.yaml
}

update_templates
add_heritage_service