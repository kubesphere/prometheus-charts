{{/*
# Containers for the calico-exporter daemonset.
*/}}
{{- define "calico-exporter.daemonset.containers" -}}
{{- $imageDict := dict "Values" (dict "image" .Values.CalicoExporter.image "global" .Values.global) }}
- name: calico-exporter
  env:
    - name: NODENAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
  image: '{{ include "calico-exporter.common.image" $imageDict }}'
  imagePullPolicy: {{ .Values.CalicoExporter.image.pullPolicy }}
  args:
    - --web.listen-address=127.0.0.1:{{ .Values.CalicoExporter.service.innerPort }}
    - --collector.enable-collectors=bgp
  resources:
{{ toYaml .Values.CalicoExporter.resources | indent 12 }}
  volumeMounts:
    - name: var-run-calico
      mountPath: /var/run/calico
{{- end }}

{{/*
# Volumes for the calico-exporter daemonset.
*/}}
{{- define "calico-exporter.daemonset.volumes" -}}
- name: var-run-calico
  hostPath:
    path: /var/run/calico
{{- end }}
