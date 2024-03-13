{{/*
# Containers for the prometheus-process-exporter daemonset.
*/}}
{{- define "prometheus-process-exporter.daemonset.containers" -}}
{{- $imageDict := dict "Values" (dict "image" .Values.ProcessExporter.image "global" .Values.global) }}
- name: process-exporter
  image: '{{ include "prometheus-process-exporter.common.image" $imageDict }}'
  imagePullPolicy: {{ .Values.ProcessExporter.image.pullPolicy }}
  args:
    - --procfs=/host/proc
    - --config.path=/var/process-exporter/config.yml
    - --web.listen-address=127.0.0.1:{{ .Values.ProcessExporter.service.innerPort }}
{{- if .Values.ProcessExporter.extraArgs }}
{{ toYaml .Values.ProcessExporter.extraArgs | indent 12 }}
{{- end }}
  resources:
{{ toYaml .Values.ProcessExporter.resources | indent 12 }}
  volumeMounts:
    - name: proc
      mountPath: /host/proc
      readOnly:  true
    - name: config
      mountPath: /var/process-exporter
          {{- if .Values.ProcessExporter.extraHostVolumeMounts }}
          {{- range $_, $mount := .Values.ProcessExporter.extraHostVolumeMounts }}
    - name: {{ $mount.name }}
      mountPath: {{ $mount.mountPath }}
      readOnly: {{ $mount.readOnly }}
          {{- if $mount.mountPropagation }}
      mountPropagation: {{ $mount.mountPropagation }}
          {{- end }}
          {{- end }}
          {{- end }}
{{- end -}}

{{/*
# Volumes for the prometheus-process-exporter daemonset.
*/}}
{{- define "prometheus-process-exporter.daemonset.volumes" -}}
- name: config
  configMap:
    name: {{ template "prometheus-process-exporter.fullname" . }}
{{- if .Values.ProcessExporter.extraHostVolumeMounts }}
{{- range $_, $mount := .Values.ProcessExporter.extraHostVolumeMounts }}
- name: {{ $mount.name }}
  hostPath:
    path: {{ $mount.hostPath }}
{{- end }}
{{- end }}
{{- end -}}
